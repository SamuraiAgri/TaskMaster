import Foundation
import SwiftUI
import Combine
import EventKit

// カレンダーモード
enum TMCalendarMode: Int {
    case month
    case week
}

// カレンダーイベント
struct CalendarEvent: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let isCompleted: Bool
    let priority: Priority
    let type: CalendarEventType
    let color: Color
}

// カレンダーイベントタイプ
enum CalendarEventType {
    case task
    case calendar
}

class CalendarViewModel: ObservableObject {
    // 公開プロパティ
    @Published var currentDate: Date = Date()
    @Published var selectedDate: Date = Date()
    @Published var calendarMode: TMCalendarMode = .month
    @Published var events: [Date: [CalendarEvent]] = [:]
    @Published var isCalendarIntegrationEnabled: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // カレンダーサービス
    private let calendarService = CalendarService.shared
    
    // データサービス
    private let dataService: DataServiceProtocol
    
    // キャンセル可能な購読
    private var cancellables = Set<AnyCancellable>()
    
    // カレンダーインテグレーション設定キー
    private let calendarIntegrationKey = "calendarIntegrationEnabled"
    
    // 初期化
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        
        // カレンダーインテグレーション設定を読み込む
        isCalendarIntegrationEnabled = UserDefaults.standard.bool(forKey: calendarIntegrationKey)
        
        // データサービスの変更通知を購読
        dataService.objectWillChange
            .sink { [weak self] _ in
                self?.loadEvents()
            }
            .store(in: &cancellables)
        
        // カレンダーサービスの権限ステータス変更を購読
        calendarService.authorizationStatusDidChange
            .sink { [weak self] _ in
                self?.checkCalendarAuthorization()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    /// 月を変更
    func changeMonth(by numberOfMonths: Int) {
        guard let newDate = Calendar.current.date(
            byAdding: .month,
            value: numberOfMonths,
            to: currentDate
        ) else { return }
        
        currentDate = newDate
        loadEvents()
    }
    
    /// 表示モードを変更（月表示/週表示）
    func changeMode(to mode: TMCalendarMode) {
        calendarMode = mode
        loadEvents()
    }
    
    /// 日付を選択
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    /// 今日へ移動
    func goToToday() {
        currentDate = Date()
        selectedDate = Date()
        loadEvents()
    }
    
    /// カレンダーインテグレーションの有効/無効を切り替え
    func toggleCalendarIntegration(completion: @escaping (Bool) -> Void) {
        if isCalendarIntegrationEnabled {
            // 無効化
            isCalendarIntegrationEnabled = false
            UserDefaults.standard.set(false, forKey: calendarIntegrationKey)
            completion(true)
        } else {
            // 有効化（カレンダーアクセス許可をリクエスト）
            requestCalendarAccess { [weak self] granted in
                guard let self = self else { return }
                self.isCalendarIntegrationEnabled = granted
                UserDefaults.standard.set(granted, forKey: self.calendarIntegrationKey)
                completion(granted)
            }
        }
    }
    
    /// カレンダーイベントを読み込む
    func loadEvents() {
        isLoading = true
        
        // タスクを取得
        let tasks = dataService.fetchTasks()
        
        // カレンダーモードに応じた期間を設定
        var startDate: Date
        var endDate: Date
        
        switch calendarMode {
        case .month:
            // 表示中の月の前後1ヶ月を含む
            guard let start = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfMonth(for: currentDate)),
                  let end = Calendar.current.date(byAdding: .month, value: 2, to: firstDayOfMonth(for: currentDate)) else {
                isLoading = false
                return
            }
            startDate = start
            endDate = end
        case .week:
            // 表示中の週の前後1週間を含む
            guard let weekStart = selectedDate.startOfWeek,
                  let start = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart),
                  let end = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: weekStart) else {
                isLoading = false
                return
            }
            startDate = start
            endDate = end
        }
        
        // タスクをカレンダーイベントに変換
        var tempEvents: [Date: [CalendarEvent]] = [:]
        
        for task in tasks {
            if let dueDate = task.dueDate {
                let dayKey = Calendar.current.startOfDay(for: dueDate)
                
                let event = CalendarEvent(
                    id: task.id,
                    title: task.title,
                    date: dueDate,
                    isCompleted: task.isCompleted,
                    priority: task.priority,
                    type: .task,
                    color: getTaskColor(task)
                )
                
                if tempEvents[dayKey] == nil {
                    tempEvents[dayKey] = [event]
                } else {
                    tempEvents[dayKey]?.append(event)
                }
            }
        }
        
        // カレンダーインテグレーションが有効な場合、iOSカレンダーのイベントも読み込む
        if isCalendarIntegrationEnabled {
            if #available(iOS 17.0, *) {
                if calendarService.authorizationStatus == .fullAccess {
                    loadCalendarEvents(startDate: startDate, endDate: endDate, tempEvents: &tempEvents)
                }
            } else {
                if calendarService.authorizationStatus == .authorized {
                    loadCalendarEvents(startDate: startDate, endDate: endDate, tempEvents: &tempEvents)
                }
            }
        }
        
        // イベントを時間順にソート
        for (day, dayEvents) in tempEvents {
            tempEvents[day] = dayEvents.sorted { $0.date < $1.date }
        }
        
        DispatchQueue.main.async {
            self.events = tempEvents
            self.isLoading = false
        }
    }
    
    // カレンダーイベントの読み込み（リファクタリングのために分離）
    private func loadCalendarEvents(startDate: Date, endDate: Date, tempEvents: inout [Date: [CalendarEvent]]) {
        let calendarEvents = calendarService.fetchEvents(from: startDate, to: endDate)
        
        for event in calendarEvents {
            let dayKey = Calendar.current.startOfDay(for: event.startDate)
            
            let calEvent = CalendarEvent(
                id: UUID(), // カレンダーイベントには一意のIDを生成
                title: event.title,
                date: event.startDate,
                isCompleted: false,
                priority: .medium,
                type: .calendar,
                color: getCalendarColor(event.calendar)
            )
            
            if tempEvents[dayKey] == nil {
                tempEvents[dayKey] = [calEvent]
            } else {
                tempEvents[dayKey]?.append(calEvent)
            }
        }
    }
    
    /// カレンダー権限のチェック
    func checkCalendarAuthorization() {
        calendarService.checkAuthorizationStatus()
        
        // 権限がなくなった場合、インテグレーションを無効に
        if #available(iOS 17.0, *) {
            if calendarService.authorizationStatus != .fullAccess && isCalendarIntegrationEnabled {
                isCalendarIntegrationEnabled = false
                UserDefaults.standard.set(false, forKey: calendarIntegrationKey)
            }
        } else {
            if calendarService.authorizationStatus != .authorized && isCalendarIntegrationEnabled {
                isCalendarIntegrationEnabled = false
                UserDefaults.standard.set(false, forKey: calendarIntegrationKey)
            }
        }
        
        loadEvents()
    }
    
    /// 特定の日のイベント数を取得
    func numberOfEvents(for date: Date) -> Int {
        let dayKey = Calendar.current.startOfDay(for: date)
        return events[dayKey]?.count ?? 0
    }
    
    /// 特定の日のイベントを取得
    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let dayKey = Calendar.current.startOfDay(for: date)
        return events[dayKey] ?? []
    }
    
    // MARK: - 月カレンダー関連のヘルパーメソッド
    
    /// 月の最初の日を取得
    func firstDayOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// 月の日数を取得
    func numberOfDaysInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 0
    }
    
    /// 月の最初の曜日を取得（0: 日曜日, 1: 月曜日, ..., 6: 土曜日）
    func firstWeekdayOfMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let firstDay = firstDayOfMonth(for: date)
        let weekday = calendar.component(.weekday, from: firstDay)
        
        // 週の始まりを月曜日にする場合の調整
        return (weekday + 5) % 7
    }
    
    /// 月カレンダーに表示する日付の配列を取得
    func daysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let firstDay = firstDayOfMonth(for: date)
        let daysInMonth = numberOfDaysInMonth(for: date)
        let firstWeekday = firstWeekdayOfMonth(for: date)
        
        var days: [Date] = []
        
        // 前月の日を追加
        for day in 0..<firstWeekday {
            if let date = calendar.date(byAdding: .day, value: -firstWeekday + day, to: firstDay) {
                days.append(date)
            }
        }
        
        // 当月の日を追加
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }
        
        // 翌月の日を追加（6週間表示の場合）
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            for day in 0..<remainingDays {
                if let date = calendar.date(byAdding: .day, value: daysInMonth + day, to: firstDay) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    // MARK: - 週カレンダー関連のヘルパーメソッド
    
    /// 選択された週の日付を取得
    func daysInWeek(for date: Date) -> [Date] {
        guard let weekStart = date.startOfWeek else {
            return []
        }
        
        let calendar = Calendar.current
        var days: [Date] = []
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: weekStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - プライベートメソッド
    
    /// カレンダーアクセス許可をリクエスト
    private func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        calendarService.requestAccess { granted, error in
            if let error = error {
                self.errorMessage = "カレンダーへのアクセスに失敗しました: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            if granted {
                self.loadEvents()
                completion(true)
            } else {
                self.errorMessage = "カレンダーへのアクセスが許可されていません。設定アプリから許可してください。"
                completion(false)
            }
        }
    }
    
    /// タスクの色を取得（優先度とプロジェクトに基づく）
    private func getTaskColor(_ task: TMTask) -> Color {
        // プロジェクトがある場合はそのプロジェクトの色を使用
        if let projectId = task.projectId, let project = dataService.getProject(by: projectId) {
            return project.color
        }
        
        // プロジェクトがない場合は優先度に基づく色を使用
        return Color.priorityColor(task.priority)
    }
    
    /// カレンダーの色を取得
    private func getCalendarColor(_ calendar: EKCalendar?) -> Color {
        guard let calendar = calendar else {
            return TMDesignSystem.Colors.secondary
        }
        
        return Color(cgColor: calendar.cgColor)
    }
}
