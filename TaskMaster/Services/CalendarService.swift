import Foundation
import EventKit

/// カレンダー関連の機能を提供するサービスクラス
class CalendarService {
    // シングルトンインスタンス
    static let shared = CalendarService()
    
    // EventKitの使用に必要なイベントストア
    private let eventStore = EKEventStore()
    
    // アクセス許可状態
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    // カレンダーアクセス許可の変更通知用
    let authorizationStatusDidChange = NotificationCenter.default.publisher(for: .EKEventStoreChanged)
    
    // 初期化
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - アクセス許可関連
    
    /// カレンダーへのアクセス許可状態を確認
    func checkAuthorizationStatus() {
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    /// カレンダーへのアクセス許可をリクエスト
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestAccess(to: .event) { [weak self] (granted, error) in
            DispatchQueue.main.async {
                self?.checkAuthorizationStatus()
                completion(granted, error)
            }
        }
    }
    
    // MARK: - カレンダーイベント操作
    
    /// タスクをカレンダーイベントとして追加する
    func addTaskToCalendar(task: Task, completion: @escaping (Bool, Error?) -> Void) {
        // 許可状態を確認
        if authorizationStatus != .authorized {
            completion(false, NSError(domain: "CalendarService", code: 1, userInfo: [NSLocalizedDescriptionKey: "カレンダーへのアクセスが許可されていません。"]))
            return
        }
        
        // 期限日がないタスクは追加できない
        guard let dueDate = task.dueDate else {
            completion(false, NSError(domain: "CalendarService", code: 2, userInfo: [NSLocalizedDescriptionKey: "タスクには期限が設定されていません。"]))
            return
        }
        
        // イベントを作成
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.notes = task.description
        
        // 終日イベントか時間指定イベントかを判断
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueDate)
        
        if timeComponents.hour == 0 && timeComponents.minute == 0 {
            // 終日イベント
            event.isAllDay = true
            event.startDate = dueDate
            event.endDate = dueDate
        } else {
            // 時間指定イベント（1時間のイベントとして作成）
            event.isAllDay = false
            event.startDate = dueDate
            event.endDate = calendar.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
        }
        
        // 優先度をアラームとして設定（高優先度は15分前、中優先度は30分前、低優先度はアラームなし）
        switch task.priority {
        case .high:
            let alarm = EKAlarm(relativeOffset: -15 * 60) // 15分前
            event.addAlarm(alarm)
        case .medium:
            let alarm = EKAlarm(relativeOffset: -30 * 60) // 30分前
            event.addAlarm(alarm)
        case .low:
            break // アラームなし
        }
        
        // アプリのデフォルトカレンダーを使用
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // タスクIDをカスタムプロパティとして保存（将来的な同期用）
        if let properties = task.id.uuidString.data(using: .utf8) {
            event.setValue(properties, forKey: "taskID")
        }
        
        // イベントを保存
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    /// 指定した期間内のカレンダーイベントを取得
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        // 許可状態を確認
        if authorizationStatus != .authorized {
            return []
        }
        
        // イベント取得用の述語を作成
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        // イベントを取得
        let events = eventStore.events(matching: predicate)
        return events
    }
    
    /// 特定の日付のカレンダーイベントを取得
    func fetchEventsForDay(_ date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        return fetchEvents(from: startOfDay, to: endOfDay)
    }
    
    /// 今週のカレンダーイベントを取得
    func fetchEventsForCurrentWeek() -> [EKEvent] {
        let calendar = Calendar.current
        guard let startOfWeek = Date().startOfWeek,
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return []
        }
        
        return fetchEvents(from: startOfWeek, to: endOfWeek)
    }
    
    /// タスクに関連するカレンダーイベントを検索
    func findEventForTask(_ task: Task) -> EKEvent? {
        // 許可状態を確認
        if authorizationStatus != .authorized || task.dueDate == nil {
            return nil
        }
        
        // タスクの期限日の前後1日のイベントを取得
        guard let dueDate = task.dueDate,
              let startDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
              let endDate = Calendar.current.date(byAdding: .day, value: 1, to: dueDate) else {
            return nil
        }
        
        let events = fetchEvents(from: startDate, to: endDate)
        
        // タスクタイトルが一致するイベントを探す
        for event in events {
            if event.title == task.title {
                return event
            }
        }
        
        return nil
    }
    
    /// タスクに関連するカレンダーイベントを更新
    func updateEventForTask(_ task: Task, completion: @escaping (Bool, Error?) -> Void) {
        guard let event = findEventForTask(task) else {
            // イベントが見つからない場合は新規作成
            addTaskToCalendar(task: task, completion: completion)
            return
        }
        
        // イベント情報を更新
        event.title = task.title
        event.notes = task.description
        
        // 期限日を更新
        if let dueDate = task.dueDate {
            // 終日イベントか時間指定イベントかを判断
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: dueDate)
            
            if timeComponents.hour == 0 && timeComponents.minute == 0 {
                // 終日イベント
                event.isAllDay = true
                event.startDate = dueDate
                event.endDate = dueDate
            } else {
                // 時間指定イベント
                event.isAllDay = false
                event.startDate = dueDate
                event.endDate = calendar.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
            }
        }
        
        // イベントを保存
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    /// タスクに関連するカレンダーイベントを削除
    func removeEventForTask(_ task: Task, completion: @escaping (Bool, Error?) -> Void) {
        guard let event = findEventForTask(task) else {
            // イベントが見つからない場合は成功扱い
            completion(true, nil)
            return
        }
        
        // イベントを削除
        do {
            try eventStore.remove(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    /// 利用可能なカレンダーの一覧を取得
    func fetchCalendars() -> [EKCalendar] {
        if authorizationStatus != .authorized {
            return []
        }
        
        return eventStore.calendars(for: .event)
    }
    
    /// タスクの完了状態に応じてカレンダーイベントを更新
    func updateEventForCompletedTask(_ task: Task, completion: @escaping (Bool, Error?) -> Void) {
        guard let event = findEventForTask(task) else {
            completion(false, nil)
            return
        }
        
        // タスクが完了した場合
        if task.isCompleted {
            // タイトルに「[完了]」のプレフィックスを追加
            if !event.title.hasPrefix("[完了]") {
                event.title = "[完了] " + event.title
            }
        } else {
            // 完了状態が解除された場合、「[完了]」のプレフィックスを削除
            if event.title.hasPrefix("[完了]") {
                event.title = event.title.replacingOccurrences(of: "[完了] ", with: "")
            }
        }
        
        // イベントを保存
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
}
