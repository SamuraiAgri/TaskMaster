import Foundation
import UserNotifications

class NotificationService {
    // シングルトンインスタンス
    static let shared = NotificationService()
    
    // 初期化
    private init() {
        requestAuthorization()
    }
    
    // 通知の許可をリクエスト
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("通知の許可リクエストに失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    // タスクの通知をスケジュールする
    func scheduleTaskReminder(for task: Task) {
        // タスクに通知日時が設定されていない場合は何もしない
        guard let reminderDate = task.reminderDate else { return }
        
        // 現在時刻より前の通知は無視
        if reminderDate <= Date() { return }
        
        // 既存の通知をキャンセル
        cancelTaskReminder(for: task)
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "タスクのリマインダー"
        content.body = task.title ?? "タスクリマインダー"
        
        if let description = task.taskDescription, !description.isEmpty {
            content.subtitle = description
        }
        
        content.sound = UNNotificationSound.default
        
        // タスクIDをユーザーインフォに追加
        if let taskId = task.id {
            content.userInfo = ["taskId": taskId.uuidString]
        }
        
        // 通知のトリガーを作成（特定の日時）
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 通知リクエストを作成
        let identifier = "task-\(task.id?.uuidString ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知の登録に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    // タスクの通知をキャンセルする
    func cancelTaskReminder(for task: Task) {
        let identifier = "task-\(task.id?.uuidString ?? UUID().uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // すべての通知をキャンセルする
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // 保留中の通知を取得する
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    // 特定のタスクの保留中の通知を取得する
    func getPendingNotification(for taskId: UUID, completion: @escaping (UNNotificationRequest?) -> Void) {
        let identifier = "task-\(taskId.uuidString)"
        
        getPendingNotifications { requests in
            let request = requests.first { $0.identifier == identifier }
            completion(request)
        }
    }
    
    // 複数のタスクの通知をスケジュールする
    func scheduleTaskReminders(for tasks: [Task]) {
        for task in tasks {
            if task.reminderDate != nil {
                scheduleTaskReminder(for: task)
            }
        }
    }
    
    // タスクを更新したときに通知も更新する
    func updateTaskReminder(for task: Task) {
        cancelTaskReminder(for: task)
        
        if task.reminderDate != nil {
            scheduleTaskReminder(for: task)
        }
    }
    
    // 今日のタスクの通知を朝にスケジュールする
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        // 既存の毎日のリマインダーをキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "今日のタスク"
        content.body = "今日のタスクを確認しましょう"
        content.sound = UNNotificationSound.default
        
        // 通知のトリガーを作成（毎日特定の時間）
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("毎日のリマインダーの登録に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    // 週次レポート通知をスケジュールする
    func scheduleWeeklyReport(dayOfWeek: Int, hour: Int, minute: Int) {
        // 既存の週次レポート通知をキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-report"])
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "週次タスクレポート"
        content.body = "今週のタスク達成状況を確認しましょう"
        content.sound = UNNotificationSound.default
        
        // 通知のトリガーを作成（毎週特定の曜日と時間）
        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek // 1=日曜日, 2=月曜日, ..., 7=土曜日
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: "weekly-report", content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("週次レポートの登録に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    // 期限切れタスクの通知をスケジュール
    func scheduleOverdueTasksReminder() {
        // 期限切れタスク通知をキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["overdue-tasks"])
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "期限切れのタスク"
        content.body = "期限が過ぎたタスクがあります。確認してください。"
        content.sound = UNNotificationSound.default
        
        // 通知のトリガーを作成（毎日夕方）
        var dateComponents = DateComponents()
        dateComponents.hour = 18 // 夕方6時
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: "overdue-tasks", content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("期限切れタスク通知の登録に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}
