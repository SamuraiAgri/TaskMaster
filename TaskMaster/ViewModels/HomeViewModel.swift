import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // 公開プロパティ
    @Published var todayTasks: [TMTask] = []
    @Published var priorityTasks: [TMTask] = []
    @Published var overdueTasks: [TMTask] = []
    @Published var upcomingTasks: [TMTask] = []
    @Published var activeProjects: [TMProject] = []
    @Published var statistics: TMStatistics = TMStatistics()
    
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
    func initialize(tasks: [TMTask], projects: [TMProject]) {
        processTasks(tasks)
        processProjects(projects)
        calculateStatistics(tasks: tasks, projects: projects)
    }
    
    // データの読み込み
    func loadData() {
        let coreDataTasks = dataService.fetchTasks()
        let coreDataProjects = dataService.fetchProjects()
        
        let tasks = coreDataTasks.map { task -> TMTask in
            TMTask(
                id: task.id ?? UUID(),
                title: task.title ?? "",
                description: task.taskDescription,
                creationDate: task.creationDate ?? Date(),
                dueDate: task.dueDate,
                completionDate: task.completionDate,
                priority: Priority(rawValue: Int(task.priority)) ?? .medium,
                status: TaskStatus(rawValue: task.status ?? "") ?? .notStarted,
                projectId: task.project?.id,
                tagIds: Array(task.tags?.compactMap { ($0 as? Tag)?.id } ?? []),
                isRepeating: task.isRepeating,
                repeatType: RepeatType(rawValue: task.repeatType ?? "") ?? .none,
                repeatCustomValue: task.repeatCustomValue != 0 ? Int(task.repeatCustomValue) : nil,
                reminderDate: task.reminderDate,
                parentTaskId: task.parentTask?.id,
                subTaskIds: Array(task.subTasks?.compactMap { ($0 as? Task)?.id } ?? [])
            )
        }
        
        let projects = coreDataProjects.map { TMProject.fromCoreData($0) }
        
        initialize(tasks: tasks, projects: projects)
    }
    
    // MARK: - プライベートメソッド
    
    // タスクの処理
    private func processTasks(_ tasks: [TMTask]) {
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
    private func processProjects(_ projects: [TMProject]) {
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
    private func calculateStatistics(tasks: [TMTask], projects: [TMProject]) {
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
