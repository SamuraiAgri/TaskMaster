import Foundation

/// 繰り返しタスクを処理するためのサービスクラス
class RepeatTaskService {
    // シングルトンインスタンス
    static let shared = RepeatTaskService()
    
    // DataService依存
    private let dataService: DataServiceProtocol
    
    // NotificationService依存
    private let notificationService: NotificationService
    
    // 初期化
    init(dataService: DataServiceProtocol = DataService.shared,
         notificationService: NotificationService = NotificationService.shared) {
        self.dataService = dataService
        self.notificationService = notificationService
    }
    
    // MARK: - 公開メソッド
    
    /// 繰り返しタスクが完了した場合に、次回のタスクを作成
    func createNextOccurrence(for task: TMTask) {
        // 繰り返しタスクでなければ何もしない
        guard task.isRepeating else { return }
        
        // 次回の期限日を計算
        guard let nextDueDate = calculateNextDueDate(for: task) else { return }
        
        // 新しいタスクを作成（基本的に同じ情報を継承）
        var newTask = task
        
        // 新しいIDを付与
        newTask.id = UUID()
        
        // 期限日を更新
        newTask.dueDate = nextDueDate
        
        // ステータスをリセット
        newTask.status = .notStarted
        
        // 完了日をリセット
        newTask.completionDate = nil
        
        // 作成日を現在に設定
        newTask.creationDate = Date()
        
        // リマインダー日を調整（元のタスクにリマインダーがある場合）
        if let originalReminderDate = task.reminderDate, let originalDueDate = task.dueDate {
            // 元のリマインダーと期限日の差分を保持
            let timeInterval = originalReminderDate.timeIntervalSince(originalDueDate)
            newTask.reminderDate = nextDueDate.addingTimeInterval(timeInterval)
        } else {
            newTask.reminderDate = nil
        }
        
        // 新しいタスクを保存
        let newCoreDataTask = Task(context: dataService.viewContext)
        updateCoreDataTask(newCoreDataTask, from: newTask)
        
        // 保存
        dataService.saveContext()
        
        // 通知の予約（リマインダーがある場合）
        if let reminderDate = newTask.reminderDate {
            let task = Task(context: dataService.viewContext)
            task.id = newTask.id
            task.title = newTask.title
            task.taskDescription = newTask.description
            task.reminderDate = reminderDate
            
            notificationService.scheduleTaskReminder(for: task)
        }
    }
    
    // MARK: - プライベートメソッド
    
    /// タスクの繰り返しタイプに基づいて次の期限日を計算
    private func calculateNextDueDate(for task: TMTask) -> Date? {
        // 期限日がなければ計算不可
        guard let dueDate = task.dueDate else { return nil }
        
        let calendar = Calendar.current
        
        switch task.repeatType {
        case .none:
            return nil
        
        case .daily:
            // 毎日繰り返し - 1日加算
            return calendar.date(byAdding: .day, value: 1, to: dueDate)
            
        case .weekdays:
            // 平日繰り返し - 次の営業日を計算
            var nextDate = calendar.date(byAdding: .day, value: 1, to: dueDate)!
            
            // 曜日が週末の場合は月曜日に調整
            let weekday = calendar.component(.weekday, from: nextDate)
            if weekday == 7 {  // 土曜日
                nextDate = calendar.date(byAdding: .day, value: 2, to: nextDate)!
            } else if weekday == 1 {  // 日曜日
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            
            return nextDate
            
        case .weekly:
            // 毎週繰り返し - 7日加算
            return calendar.date(byAdding: .day, value: 7, to: dueDate)
            
        case .monthly:
            // 毎月繰り返し - 1ヶ月加算
            let monthlyDate = calendar.date(byAdding: .month, value: 1, to: dueDate)
            
            // 例：31日から始まる場合、次の月に31日がなければ月末にする
            return adjustToValidMonthDay(date: monthlyDate, originalDate: dueDate)
            
        case .yearly:
            // 毎年繰り返し - 1年加算
            let yearlyDate = calendar.date(byAdding: .year, value: 1, to: dueDate)
            
            // 閏年の2月29日対応
            return adjustToValidMonthDay(date: yearlyDate, originalDate: dueDate)
            
        case .custom:
            // カスタム繰り返し値が必要
            guard let customValue = task.repeatCustomValue else { return nil }
            
            // カスタム値に基づいて日数を加算
            return calendar.date(byAdding: .day, value: customValue, to: dueDate)
        }
    }
    
    /// 月の日付調整（31日→30日など、月によって有効な日付を調整）
    private func adjustToValidMonthDay(date: Date?, originalDate: Date) -> Date? {
        guard let date = date else { return nil }
        
        let calendar = Calendar.current
        
        // 元の日
        let originalDay = calendar.component(.day, from: originalDate)
        
        // 新しい年月
        let newYear = calendar.component(.year, from: date)
        let newMonth = calendar.component(.month, from: date)
        
        // 新しい月の最終日を取得
        let range = calendar.range(of: .day, in: .month, for: date)
        let lastDay = range?.upperBound ?? 31
        
        // 新しい日（元の日と月末の小さい方）
        let newDay = min(originalDay, lastDay)
        
        // 日付コンポーネントを作成
        var components = DateComponents()
        components.year = newYear
        components.month = newMonth
        components.day = newDay
        
        // 元の時間も保持する
        components.hour = calendar.component(.hour, from: originalDate)
        components.minute = calendar.component(.minute, from: originalDate)
        components.second = calendar.component(.second, from: originalDate)
        
        return calendar.date(from: components)
    }
    
    /// TMTaskからCoreDataのTaskに更新
    private func updateCoreDataTask(_ coreDataTask: Task, from tmTask: TMTask) {
        coreDataTask.id = tmTask.id
        coreDataTask.title = tmTask.title
        coreDataTask.taskDescription = tmTask.description
        coreDataTask.creationDate = tmTask.creationDate
        coreDataTask.dueDate = tmTask.dueDate
        coreDataTask.completionDate = tmTask.completionDate
        coreDataTask.priority = Int16(tmTask.priority.rawValue)
        coreDataTask.status = tmTask.status.rawValue
        coreDataTask.isRepeating = tmTask.isRepeating
        coreDataTask.repeatType = tmTask.repeatType.rawValue
        coreDataTask.repeatCustomValue = tmTask.repeatCustomValue != nil ? Int16(tmTask.repeatCustomValue!) : 0
        coreDataTask.reminderDate = tmTask.reminderDate
        
        // プロジェクト関連付け
        if let projectId = tmTask.projectId {
            coreDataTask.project = dataService.getProject(by: projectId)
        }
        
        // タグ関連付け
        for tagId in tmTask.tagIds {
            if let tag = dataService.getTag(by: tagId) {
                coreDataTask.addToTags(tag)
            }
        }
        
        // 親タスク関連付け
        if let parentTaskId = tmTask.parentTaskId {
            coreDataTask.parentTask = dataService.getTask(by: parentTaskId)
        }
    }
}
