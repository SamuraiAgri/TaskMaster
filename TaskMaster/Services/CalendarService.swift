import Foundation
import EventKit
import Combine

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
        if #available(iOS 17.0, *) {
            self.authorizationStatus = eventStore.authorizationStatus(for: .event)
        } else {
            // iOS 17より前はクラスメソッドを使用
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    /// カレンダーへのアクセス許可をリクエスト
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.checkAuthorizationStatus()
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.checkAuthorizationStatus()
                    completion(granted, error)
                }
            }
        }
    }
    
    // MARK: - カレンダーイベント操作
    
    /// タスクをカレンダーイベントとして追加する
    func addTaskToCalendar(task: TMTask, completion: @escaping (Bool, Error?) -> Void) {
        // 許可状態を確認
        if #available(iOS 17.0, *) {
            if authorizationStatus != .fullAccess {
                completion(false, NSError(domain: "CalendarService", code: 1, userInfo: [NSLocalizedDescriptionKey: "カレンダーへのアクセスが許可されていません。"]))
                return
            }
        } else {
            if authorizationStatus != .authorized {
                completion(false, NSError(domain: "CalendarService", code: 1, userInfo: [NSLocalizedDescriptionKey: "カレンダーへのアクセスが許可されていません。"]))
                return
            }
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
        if #available(iOS 17.0, *) {
            // iOS 17での許可状態確認
            if authorizationStatus != .fullAccess {
                return []
            }
        } else {
            // iOS 17より前の許可状態確認
            if authorizationStatus != .authorized {
                return []
            }
        }
        
        // イベント取得用の述語を作成
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        // イベントを取得
        let events = eventStore.events(matching: predicate)
        return events
    }
}
