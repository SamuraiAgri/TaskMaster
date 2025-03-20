import Foundation
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    // 公開プロパティ
    @Published var statisticsData: TMStatistics = TMStatistics()
    @Published var projectProgressData: [ProjectProgress] = []
    @Published var tagsDistributionData: [TagsDistribution] = []
    @Published var priorityDistribution: [PriorityDistribution] = []
    @Published var statusDistribution: [StatusDistribution] = []
    @Published var dailyCompletions: [DailyCompletion] = []
    @Published var selectedTimeFrame: TMTimeFrame = .week
    
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
                self?.loadStatistics()
            }
            .store(in: &cancellables)
        
        // 期間選択の変更を監視
        $selectedTimeFrame
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    // 統計データの読み込み
    func loadStatistics() {
        // CoreDataから必要なデータを取得
        let tasks = dataService.fetchTasks().map { TMTask.fromCoreData($0) }
        let projects = dataService.fetchProjects().map { TMProject.fromCoreData($0) }
        let tags = dataService.fetchTags().map { TMTag.fromCoreData($0) }
        
        // 期間に応じたデータのフィルタリング
        let filteredTasks = filterTasksByTimeFrame(tasks)
        
        // 各種統計情報の計算
        calculateTaskStatistics(tasks: filteredTasks)
        calculateProjectProgress(tasks: filteredTasks, projects: projects)
        calculateTagsDistribution(tasks: filteredTasks, tags: tags)
        calculatePriorityDistribution(tasks: filteredTasks)
        calculateStatusDistribution(tasks: filteredTasks)
        calculateDailyCompletions(tasks: filteredTasks)
    }
    
    // MARK: - プライベートメソッド
    
    // 期間でタスクをフィルタリング
    private func filterTasksByTimeFrame(_ tasks: [TMTask]) -> [TMTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch selectedTimeFrame {
        case .week:
            guard let startOfWeek = today.startOfWeek,
                  let endOfWeek = today.endOfWeek else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= startOfWeek && completionDate <= endOfWeek
                }
                return false
            }
            
        case .month:
            guard let startOfMonth = today.startOfMonth,
                  let endOfMonth = today.endOfMonth else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= startOfMonth && completionDate <= endOfMonth
                }
                return false
            }
            
        case .year:
            guard let startOfYear = today.startOfYear,
                  let endOfYear = today.endOfYear else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= startOfYear && completionDate <= endOfYear
                }
                return false
            }
            
        case .all:
            return tasks
        }
    }
    
    // タスク統計情報の計算
    private func calculateTaskStatistics(tasks: [TMTask]) {
        // 総タスク数
        statisticsData.totalTasks = tasks.count
        
        // 完了タスク数
        let completedTasks = tasks.filter { $0.isCompleted }
        statisticsData.completedTasks = completedTasks.count
        
        // 完了率
        statisticsData.completionRate = tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count)
        
        // 期限内に完了したタスク数
        let tasksCompletedOnTime = completedTasks.filter { task in
            if let dueDate = task.dueDate, let completionDate = task.completionDate {
                return completionDate <= dueDate
            }
            return false
        }
        statisticsData.tasksCompletedOnTime = tasksCompletedOnTime.count
        
        // 期限内完了率
        statisticsData.onTimeCompletionRate = completedTasks.isEmpty ? 0 : Double(tasksCompletedOnTime.count) / Double(completedTasks.count)
        
        // 優先度別タスク数
        statisticsData.highPriorityTasks = tasks.filter { $0.priority == .high }.count
        statisticsData.mediumPriorityTasks = tasks.filter { $0.priority == .medium }.count
        statisticsData.lowPriorityTasks = tasks.filter { $0.priority == .low }.count
    }
    
    // プロジェクト進捗の計算
    private func calculateProjectProgress(tasks: [TMTask], projects: [TMProject]) {
        var projectProgress: [ProjectProgress] = []
        
        for project in projects {
            let projectTasks = tasks.filter { $0.projectId == project.id }
            let completedTasks = projectTasks.filter { $0.isCompleted }
            let progress = projectTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(projectTasks.count)
            
            projectProgress.append(
                ProjectProgress(
                    id: project.id,
                    name: project.name,
                    progress: progress,
                    color: project.color,
                    taskCount: projectTasks.count
                )
            )
        }
        
        self.projectProgressData = projectProgress.sorted { $0.progress > $1.progress }
    }
    
    // タグ分布の計算
    private func calculateTagsDistribution(tasks: [TMTask], tags: [TMTag]) {
        var tagsDistribution: [TagsDistribution] = []
        
        for tag in tags {
            let taggedTasks = tasks.filter { $0.tagIds.contains(tag.id) }
            
            tagsDistribution.append(
                TagsDistribution(
                    id: tag.id,
                    name: tag.name,
                    count: taggedTasks.count,
                    color: tag.color
                )
            )
        }
        
        self.tagsDistributionData = tagsDistribution.sorted { $0.count > $1.count }
    }
    
    // 優先度分布の計算
    private func calculatePriorityDistribution(tasks: [TMTask]) {
        let highPriorityTasks = tasks.filter { $0.priority == .high }
        let mediumPriorityTasks = tasks.filter { $0.priority == .medium }
        let lowPriorityTasks = tasks.filter { $0.priority == .low }
        
        self.priorityDistribution = [
            PriorityDistribution(
                priority: .high,
                count: highPriorityTasks.count,
                color: Color.priorityColor(Priority.high)
            ),
            PriorityDistribution(
                priority: .medium,
                count: mediumPriorityTasks.count,
                color: Color.priorityColor(Priority.medium)
            ),
            PriorityDistribution(
                priority: .low,
                count: lowPriorityTasks.count,
                color: Color.priorityColor(Priority.low)
            )
        ]
    }
    
    // ステータス分布の計算
    private func calculateStatusDistribution(tasks: [TMTask]) {
        let notStartedTasks = tasks.filter { $0.status == .notStarted }
        let inProgressTasks = tasks.filter { $0.status == .inProgress }
        let completedTasks = tasks.filter { $0.status == .completed }
        let postponedTasks = tasks.filter { $0.status == .postponed }
        let cancelledTasks = tasks.filter { $0.status == .cancelled }
        
        self.statusDistribution = [
            StatusDistribution(
                status: .notStarted,
                count: notStartedTasks.count,
                color: Color.statusColor(TaskStatus.notStarted)
            ),
            StatusDistribution(
                status: .inProgress,
                count: inProgressTasks.count,
                color: Color.statusColor(TaskStatus.inProgress)
            ),
            StatusDistribution(
                status: .completed,
                count: completedTasks.count,
                color: Color.statusColor(TaskStatus.completed)
            ),
            StatusDistribution(
                status: .postponed,
                count: postponedTasks.count,
                color: Color.statusColor(TaskStatus.postponed)
            ),
            StatusDistribution(
                status: .cancelled,
                count: cancelledTasks.count,
                color: Color.statusColor(TaskStatus.cancelled)
            )
        ].filter { $0.count > 0 }
    }
    
    // 日毎の完了タスク集計
    private func calculateDailyCompletions(tasks: [TMTask]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var results: [DailyCompletion] = []
        
        // 最近7日間のデータを取得
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else {
                continue
            }
            
            // その日に完了したタスクをカウント
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let completedTasksOnDay = tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= dayStart && completionDate < dayEnd
                }
                return false
            }
            
            results.append(
                DailyCompletion(
                    day: calendar.component(.weekday, from: date),
                    date: date,
                    count: completedTasksOnDay.count
                )
            )
        }
        
        // 日付でソート（古い順）
        self.dailyCompletions = results.sorted { $0.date < $1.date }
    }
    
    // 指定期間のタスク完了カウントグラフデータ
    func getCompletionChartData() -> [Int] {
        return dailyCompletions.map { $0.count }
    }
    
    // 曜日ラベルの取得
    func getDayLabels() -> [String] {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return dailyCompletions.map { weekdays[$0.day % 7] }
    }
}

// TMTask拡張 - CoreDataからの変換
extension TMTask {
    static func fromCoreData(_ task: Task) -> TMTask {
        return TMTask(
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
}
