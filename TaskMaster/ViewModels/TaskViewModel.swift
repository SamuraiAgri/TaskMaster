import Foundation
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    // 公開プロパティ
    @Published var tasks: [TMTask] = []
    @Published var filteredTasks: [TMTask] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedSortOption: TaskSortOption = .dueDate
    @Published var isAscending: Bool = true
    
    // データサービス
    private let dataService: DataServiceProtocol
    
    // キャンセル可能な購読
    private var cancellables = Set<AnyCancellable>()
    
    // 初期化
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        
        // 検索テキスト、フィルター、ソートオプションの変更を監視して自動で再フィルタリング
        Publishers.CombineLatest4(
            $tasks,
            $searchText,
            $selectedFilter,
            $selectedSortOption
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] (tasks, searchText, filter, sortOption) in
            self?.filterAndSortTasks()
        }
        .store(in: &cancellables)
        
        // 昇順・降順の変更を監視
        $isAscending
            .sink { [weak self] _ in
                self?.filterAndSortTasks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    // タスクの読み込み
    func loadTasks() {
        tasks = dataService.fetchTasks().map { task in
            // Task型をTMTask型に変換するロジックを記述
            TMTask(
                id: task.id ?? UUID(),
                title: task.title ?? "",
                description: task.taskDescription,
                creationDate: task.creationDate ?? Date(),
                dueDate: task.dueDate,
                priorityAndCompletion: task.completionDate,
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
        filterAndSortTasks()
    }
    
    // タスクの追加
    func addTask(_ task: TMTask) {
        // TMTaskをCoreDataのTaskに変換
        let newTask = Task(context: dataService.viewContext)
        newTask.id = task.id
        newTask.title = task.title
        newTask.taskDescription = task.description
        newTask.creationDate = task.creationDate
        newTask.dueDate = task.dueDate
        newTask.completionDate = task.completionDate
        newTask.priority = Int16(task.priority.rawValue)
        newTask.status = task.status.rawValue
        newTask.isRepeating = task.isRepeating
        newTask.repeatType = task.repeatType.rawValue
        newTask.repeatCustomValue = task.repeatCustomValue != nil ? Int16(task.repeatCustomValue!) : 0
        newTask.reminderDate = task.reminderDate
        
        // プロジェクト関連付け
        if let projectId = task.projectId,
           let project = dataService.getProject(by: projectId) {
            newTask.project = project
        }
        
        // タグ関連付け
        for tagId in task.tagIds {
            if let tag = dataService.getTag(by: tagId) {
                newTask.addToTags(tag)
            }
        }
        
        // 親タスク関連付け
        if let parentTaskId = task.parentTaskId,
           let parentTask = dataService.getTask(by: parentTaskId) {
            newTask.parentTask = parentTask
        }
        
        dataService.saveContext()
        loadTasks()
    }
    
    // タスクの更新
    func updateTask(_ task: TMTask) {
        if let existingTask = dataService.getTask(by: task.id) {
            existingTask.title = task.title
            existingTask.taskDescription = task.description
            existingTask.dueDate = task.dueDate
            existingTask.completionDate = task.completionDate
            existingTask.priority = Int16(task.priority.rawValue)
            existingTask.status = task.status.rawValue
            existingTask.isRepeating = task.isRepeating
            existingTask.repeatType = task.repeatType.rawValue
            existingTask.repeatCustomValue = task.repeatCustomValue != nil ? Int16(task.repeatCustomValue!) : 0
            existingTask.reminderDate = task.reminderDate
            
            // プロジェクト関連付け
            if let projectId = task.projectId,
               let project = dataService.getProject(by: projectId) {
                existingTask.project = project
            } else {
                existingTask.project = nil
            }
            
            // タグ関連付け
            existingTask.removeFromTags(existingTask.tags ?? NSSet())
            for tagId in task.tagIds {
                if let tag = dataService.getTag(by: tagId) {
                    existingTask.addToTags(tag)
                }
            }
            
            // 親タスク関連付け
            if let parentTaskId = task.parentTaskId,
               let parentTask = dataService.getTask(by: parentTaskId) {
                existingTask.parentTask = parentTask
            } else {
                existingTask.parentTask = nil
            }
            
            dataService.saveContext()
            loadTasks()
        }
    }
    
    // タスクの削除
    func deleteTask(at indexSet: IndexSet) {
        for index in indexSet {
            let task = filteredTasks[index]
            dataService.deleteTask(id: task.id)
        }
        loadTasks()
    }
    
    // タスクの削除（ID指定）
    func deleteTask(id: UUID) {
        dataService.deleteTask(id: id)
        loadTasks()
    }
    
    // タスクの取得（ID指定）
    func getTask(by id: UUID) -> TMTask? {
        return tasks.first { $0.id == id }
    }
    
    // タスクステータスの切り替え
    func toggleTaskCompletion(_ task: TMTask) {
        var updatedTask = task
        
        if task.isCompleted {
            updatedTask.status = .notStarted
            updatedTask.completionDate = nil
        } else {
            updatedTask.status = .completed
            updatedTask.completionDate = Date()
        }
        
        updateTask(updatedTask)
    }
    
    // タスク期限による色取得
    func dueDateColor(for task: TMTask) -> Color {
        guard let daysUntilDue = task.daysUntilDue else {
            return TMDesignSystem.Colors.textSecondary
        }
        
        if task.isCompleted {
            return TMDesignSystem.Colors.success
        } else if daysUntilDue < 0 {
            return TMDesignSystem.Colors.error
        } else if daysUntilDue == 0 {
            return TMDesignSystem.Colors.warning
        } else if daysUntilDue <= 2 {
            return TMDesignSystem.Colors.info
        } else {
            return TMDesignSystem.Colors.textSecondary
        }
    }
    
    // プロジェクトに属するタスクのフィルタリング
    func tasksForProject(_ projectId: UUID) -> [TMTask] {
        return tasks.filter { $0.projectId == projectId }
    }
    
    // タグに属するタスクのフィルタリング
    func tasksForTag(_ tagId: UUID) -> [TMTask] {
        return tasks.filter { $0.tagIds.contains(tagId) }
    }
    
    // 今日のタスク取得
    func todayTasks() -> [TMTask] {
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDateInToday(dueDate) && !task.isCompleted
            }
            return false
        }
    }
    
    // 明日のタスク取得
    func tomorrowTasks() -> [TMTask] {
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDateInTomorrow(dueDate) && !task.isCompleted
            }
            return false
        }
    }
    
    // 期限切れのタスク取得
    func overdueTasks() -> [TMTask] {
        return tasks.filter { task in
            return task.isOverdue && !task.isCompleted
        }
    }
    
    // 完了したタスク取得
    func completedTasks() -> [TMTask] {
        return tasks.filter { $0.isCompleted }
    }
    
    // 指定した日付のタスク取得
    func tasksForDate(_ date: Date) -> [TMTask] {
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    // MARK: - プライベートメソッド
    
    // フィルタリングとソート処理
    private func filterAndSortTasks() {
        var result = tasks
        
        // 検索テキストによるフィルタリング
        if !searchText.isEmpty {
            result = result.filter { task in
                task.title.lowercased().contains(searchText.lowercased()) ||
                task.description?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
        
        // フィルター条件による絞り込み
        switch selectedFilter {
        case .all:
            break // すべてのタスクを表示
        case .today:
            result = result.filter { task in
                if let dueDate = task.dueDate {
                    return Calendar.current.isDateInToday(dueDate)
                }
                return false
            }
        case .upcoming:
            result = result.filter { task in
                if let dueDate = task.dueDate, let daysUntilDue = task.daysUntilDue {
                    return daysUntilDue >= 0 && !task.isCompleted
                }
                return false
            }
        case .overdue:
            result = result.filter { task in
                return task.isOverdue
            }
        case .completed:
            result = result.filter { task in
                return task.isCompleted
            }
        case .highPriority:
            result = result.filter { task in
                return task.priority == .high && !task.isCompleted
            }
        }
        
        // ソート
        switch selectedSortOption {
        case .dueDate:
            result.sort { task1, task2 in
                // 期限なしのタスクは最後に
                if task1.dueDate == nil && task2.dueDate == nil {
                    return task1.title < task2.title
                } else if task1.dueDate == nil {
                    return false
                } else if task2.dueDate == nil {
                    return true
                } else {
                    return isAscending ? task1.dueDate! < task2.dueDate! : task1.dueDate! > task2.dueDate!
                }
            }
        case .priority:
            result.sort { task1, task2 in
                if task1.priority.rawValue == task2.priority.rawValue {
                    if let date1 = task1.dueDate, let date2 = task2.dueDate {
                        return isAscending ? date1 < date2 : date1 > date2
                    } else if task1.dueDate == nil && task2.dueDate != nil {
                        return false
                    } else if task1.dueDate != nil && task2.dueDate == nil {
                        return true
                    } else {
                        return task1.title < task2.title
                    }
                } else {
                    return isAscending ? task1.priority.rawValue < task2.priority.rawValue : task1.priority.rawValue > task2.priority.rawValue
                }
            }
        case .title:
            result.sort { task1, task2 in
                isAscending ? task1.title < task2.title : task1.title > task2.title
            }
        case .creationDate:
            result.sort { task1, task2 in
                isAscending ? task1.creationDate < task2.creationDate : task1.creationDate > task2.creationDate
            }
        case .completionDate:
            result.sort { task1, task2 in
                if task1.completionDate == nil && task2.completionDate == nil {
                    return task1.title < task2.title
                } else if task1.completionDate == nil {
                    return false
                } else if task2.completionDate == nil {
                    return true
                } else {
                    return isAscending ? task1.completionDate! < task2.completionDate! : task1.completionDate! > task2.completionDate!
                }
            }
        }
        
        filteredTasks = result
    }
}

// タスクのフィルター種類
enum TaskFilter {
    case all
    case today
    case upcoming
    case overdue
    case completed
    case highPriority
    
    var title: String {
        switch self {
        case .all: return "すべて"
        case .today: return "今日"
        case .upcoming: return "予定"
        case .overdue: return "期限切れ"
        case .completed: return "完了済み"
        case .highPriority: return "高優先"
        }
    }
}

// タスクのソート種類
enum TaskSortOption {
    case dueDate
    case priority
    case title
    case creationDate
    case completionDate
    
    var title: String {
        switch self {
        case .dueDate: return "期限日"
        case .priority: return "優先度"
        case .title: return "タイトル"
        case .creationDate: return "作成日"
        case .completionDate: return "完了日"
        }
    }
}
