import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // 公開プロパティ
    @Published var todayTasks: [Task] = []
    @Published var priorityTasks: [Task] = []
    @Published var overdueTasks: [Task] = []
    @Published var upcomingTasks: [Task] = []
    @Published var activeProjects: [Project] = []
    @Published var statistics: Statistics = Statistics()
    
    // データサービス
    private let dataService: DataServiceProtocol
    
    // キャンセル可能な購読
    private var cancellables = Set<AnyCancellable>()
    
    // 初期化
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        
        // データサービスの変更通知を購読
        dataService.objectWillChange
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    // データの初期化
    func initialize(tasks: [Task], projects: [Project]) {
        processTasks(tasks)
        processProjects(projects)
        calculateStatistics(tasks: tasks, projects: projects)
    }
    
    // データの読み込み
    func loadData() {
        let tasks = dataService.fetchTasks()
        let projects = dataService.fetchProjects()
        
        initialize(tasks: tasks, projects: projects)
    }
    
    // MARK: - プライベートメソッド
    
    // タスクの処理
    private func processTasks(_ tasks: [Task]) {
        // 今日のタスク
        todayTasks = tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDateInToday(dueDate) && !task.isCompleted
            }
            return false
        }
        
        // 高優先度のタスク
        priorityTasks = tasks.filter { task in
            return task.priority == .high && !task.isCompleted
        }.sorted { task1, task2 in
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else if task1.dueDate != nil {
                return true
            } else if task2.dueDate != nil {
                return false
            } else {
                return task1.title < task2.title
            }
        }
        
        // 期限切れのタスク
        overdueTasks = tasks.filter { task in
            return task.isOverdue && !task.isCompleted
        }.sorted { task1, task2 in
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else {
                return task1.title < task2.title
            }
        }
        
        // 今後のタスク（今日以降の7日間）
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateInterval = calendar.dateInterval(of: .weekOfMonth, for: today)!
        let endDate = calendar.date(byAdding: .day, value: 7, to: today)!
        
        upcomingTasks = tasks.filter { task in
            if let dueDate = task.dueDate, !task.isCompleted {
                let taskDay = calendar.startOfDay(for: dueDate)
                return taskDay >= today && taskDay <= endDate
            }
            return false
        }.sorted { task1, task2 in
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else {
                return task1.title < task2.title
            }
        }
    }
    
    // プロジェクトの処理
    private func processProjects(_ projects: [Project]) {
        // 進行中のプロジェクト（完了していないもの）
        activeProjects = projects.filter { !$0.isCompleted }
            .sorted { project1, project2 in
                if let date1 = project1.dueDate, let date2 = project2.dueDate {
                    return date1 < date2
                } else if project1.dueDate != nil {
                    return true
                } else if project2.dueDate != nil {
                    return false
                } else {
                    return project1.name < project2.name
                }
            }
    }
    
    // 統計情報の計算
    private func calculateStatistics(tasks: [Task], projects: [Project]) {
        // 総タスク数
        statistics.totalTasks = tasks.count
        
        // 完了タスク数
        let completedTasks = tasks.filter { $0.isCompleted }
        statistics.completedTasks = completedTasks.count
        
        // 完了率
        statistics.completionRate = tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count)
        
        // 期限内に完了したタスク数
        let tasksCompletedOnTime = completedTasks.filter { task in
            if let dueDate = task.dueDate, let completionDate = task.completionDate {
                return completionDate <= dueDate
            }
            return false
        }
        statistics.tasksCompletedOnTime = tasksCompletedOnTime.count
        
        // 期限内完了率
        statistics.onTimeCompletionRate = completedTasks.isEmpty ? 0 : Double(tasksCompletedOnTime.count) / Double(completedTasks.count)
        
        // 優先度別タスク数
        statistics.highPriorityTasks = tasks.filter { $0.priority == .high }.count
        statistics.mediumPriorityTasks = tasks.filter { $0.priority == .medium }.count
        statistics.lowPriorityTasks = tasks.filter { $0.priority == .low }.count
        
        // 今週のタスク完了数
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = weekday == 1 ? -6 : -(weekday - 2) // 月曜日を週の初めとする
        
        if let monday = calendar.date(byAdding: .day, value: daysToMonday, to: today),
           let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday) {
            
            let weekRange = monday..<nextMonday
            
            // 今週完了したタスク
            let thisWeekCompletedTasks = completedTasks.filter { task in
                if let completionDate = task.completionDate {
                    return weekRange.contains(completionDate)
                }
                return false
            }
            
            statistics.tasksCompletedThisWeek = thisWeekCompletedTasks.count
            
            // 曜日別の完了タスク数
            var dayCompletions = [Int](repeating: 0, count: 7)
            
            for task in thisWeekCompletedTasks {
                if let completionDate = task.completionDate {
                    let weekdayIndex = calendar.component(.weekday, from: completionDate)
                    // weekdayIndex: 1=日曜日, 2=月曜日, ..., 7=土曜日
                    // 配列に合わせて調整（0=月曜日, 1=火曜日, ..., 6=日曜日）
                    let adjustedIndex = (weekdayIndex + 5) % 7
                    dayCompletions[adjustedIndex] += 1
                }
            }
            
            statistics.dailyCompletions = dayCompletions
        }
        
        // アクティブなプロジェクト数
        statistics.activeProjects = projects.filter { !$0.isCompleted }.count
        
        // 完了したプロジェクト数
        statistics.completedProjects = projects.filter { $0.isCompleted }.count
    }
}

// 統計情報の構造体
struct Statistics {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var completionRate: Double = 0
    var tasksCompletedOnTime: Int = 0
    var onTimeCompletionRate: Double = 0
    var highPriorityTasks: Int = 0
    var mediumPriorityTasks: Int = 0
    var lowPriorityTasks: Int = 0
    var tasksCompletedThisWeek: Int = 0
    var dailyCompletions: [Int] = [0, 0, 0, 0, 0, 0, 0] // 月、火、水、木、金、土、日
    var activeProjects: Int = 0
    var completedProjects: Int = 0
}
