import Foundation
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    // 公開プロパティ
    @Published var statistics: Statistics = Statistics()
    @Published var selectedTimeFrame: TimeFrame = .week
    @Published var selectedCategory: StatisticsCategory = .tasks
    @Published var isLoading: Bool = false
    @Published var projectsProgress: [ProjectProgress] = []
    @Published var tagsDistribution: [TagsDistribution] = []
    @Published var priorityDistribution: [PriorityDistribution] = []
    @Published var statusDistribution: [StatusDistribution] = []
    @Published var weeklyCompletions: [DailyCompletion] = []
    @Published var monthlyCompletions: [DailyCompletion] = []
    
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
        
        // 期間やカテゴリの変更を監視
        Publishers.CombineLatest($selectedTimeFrame, $selectedCategory)
            .sink { [weak self] (timeFrame, category) in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公開メソッド
    
    /// データを読み込み、統計を計算
    func loadData() {
        isLoading = true
        
        // タスクとプロジェクトを取得
        let tasks = dataService.fetchTasks()
        let projects = dataService.fetchProjects()
        let tags = dataService.fetchTags()
        
        // 期間に基づいてフィルタリング
        let filteredTasks = filterTasksByTimeFrame(tasks)
        
        // 統計情報を計算
        calculateStatistics(tasks: filteredTasks, allTasks: tasks, projects: projects, tags: tags)
        calculateProjectsProgress(tasks: tasks, projects: projects)
        calculateTagsDistribution(tasks: filteredTasks, tags: tags)
        calculatePriorityDistribution(tasks: filteredTasks)
        calculateStatusDistribution(tasks: filteredTasks)
        calculateCompletionTimeline(tasks: tasks)
        
        isLoading = false
    }
    
    /// 週間または月間の特定の日のタスク完了数を取得
    func completionsForDay(_ day: Int, isWeekly: Bool = true) -> Int {
        if isWeekly {
            return day < weeklyCompletions.count ? weeklyCompletions[day].count : 0
        } else {
            return day < monthlyCompletions.count ? monthlyCompletions[day].count : 0
        }
    }
    
    /// 曜日ラベルを取得
    func dayLabel(_ index: Int) -> String {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        return days[index % 7]
    }
    
    /// 曜日の色を取得（今日の曜日は強調表示）
    func dayColor(_ index: Int) -> Color {
        let today = Calendar.current.component(.weekday, from: Date())
        // 日曜日=1, 月曜日=2, ..., 土曜日=7
        let todayAdjusted = today == 1 ? 6 : today - 2 // 月曜日=0, 火曜日=1, ..., 日曜日=6
        
        return index == todayAdjusted ? DesignSystem.Colors.accent : DesignSystem.Colors.primary
    }
    
    // MARK: - プライベートメソッド
    
    /// 期間でタスクをフィルタリング
    private func filterTasksByTimeFrame(_ tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFrame {
        case .week:
            // 過去7日間
            guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= oneWeekAgo
                }
                return false
            }
            
        case .month:
            // 過去30日間
            guard let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: now) else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= oneMonthAgo
                }
                return false
            }
            
        case .year:
            // 過去365日間
            guard let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: now) else {
                return tasks
            }
            return tasks.filter { task in
                if let completionDate = task.completionDate {
                    return completionDate >= oneYearAgo
                }
                return false
            }
            
        case .all:
            // すべての期間
            return tasks
        }
    }
    
    /// 主要な統計情報を計算
    private func calculateStatistics(tasks: [Task], allTasks: [Task], projects: [Project], tags: [Tag]) {
        // 総タスク数
        statistics.totalTasks = allTasks.count
        
        // 完了タスク数
        /// 主要な統計情報を計算
            private func calculateStatistics(tasks: [Task], allTasks: [Task], projects: [Project], tags: [Tag]) {
                // 総タスク数
                statistics.totalTasks = allTasks.count
                
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
                    let thisWeekCompletedTasks = allTasks.filter { task in
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
                
                // 使用中のタグ数
                statistics.activeTags = tags.filter { !$0.taskIds.isEmpty }.count
            }
            
            /// プロジェクトの進捗状況を計算
            private func calculateProjectsProgress(tasks: [Task], projects: [Project]) {
                var progress: [ProjectProgress] = []
                
                for project in projects {
                    let projectTasks = tasks.filter { task in
                        project.taskIds.contains(task.id)
                    }
                    
                    if !projectTasks.isEmpty {
                        let completedTasks = projectTasks.filter { $0.isCompleted }.count
                        let progressValue = Double(completedTasks) / Double(projectTasks.count)
                        
                        progress.append(ProjectProgress(
                            id: project.id,
                            name: project.name,
                            progress: progressValue,
                            color: project.color,
                            taskCount: projectTasks.count
                        ))
                    }
                }
                
                // 進捗率でソート（降順）
                projectsProgress = progress.sorted { $0.progress > $1.progress }
            }
            
            /// タグの分布を計算
            private func calculateTagsDistribution(tasks: [Task], tags: [Tag]) {
                var distribution: [TagsDistribution] = []
                
                for tag in tags {
                    let taggedTasks = tasks.filter { task in
                        task.tagIds.contains(tag.id)
                    }
                    
                    if !taggedTasks.isEmpty {
                        distribution.append(TagsDistribution(
                            id: tag.id,
                            name: tag.name,
                            count: taggedTasks.count,
                            color: tag.color
                        ))
                    }
                }
                
                // タスク数でソート（降順）
                tagsDistribution = distribution.sorted { $0.count > $1.count }
            }
            
            /// 優先度の分布を計算
            private func calculatePriorityDistribution(tasks: [Task]) {
                let high = tasks.filter { $0.priority == .high }.count
                let medium = tasks.filter { $0.priority == .medium }.count
                let low = tasks.filter { $0.priority == .low }.count
                
                priorityDistribution = [
                    PriorityDistribution(priority: .high, count: high, color: DesignSystem.Colors.error),
                    PriorityDistribution(priority: .medium, count: medium, color: DesignSystem.Colors.warning),
                    PriorityDistribution(priority: .low, count: low, color: DesignSystem.Colors.info)
                ]
            }
            
            /// ステータスの分布を計算
            private func calculateStatusDistribution(tasks: [Task]) {
                let notStarted = tasks.filter { $0.status == .notStarted }.count
                let inProgress = tasks.filter { $0.status == .inProgress }.count
                let completed = tasks.filter { $0.status == .completed }.count
                let postponed = tasks.filter { $0.status == .postponed }.count
                let cancelled = tasks.filter { $0.status == .cancelled }.count
                
                statusDistribution = [
                    StatusDistribution(status: .notStarted, count: notStarted, color: DesignSystem.Colors.info),
                    StatusDistribution(status: .inProgress, count: inProgress, color: DesignSystem.Colors.primary),
                    StatusDistribution(status: .completed, count: completed, color: DesignSystem.Colors.success),
                    StatusDistribution(status: .postponed, count: postponed, color: DesignSystem.Colors.warning),
                    StatusDistribution(status: .cancelled, count: cancelled, color: DesignSystem.Colors.error)
                ]
            }
            
            /// 完了タイムラインを計算（週次・月次）
            private func calculateCompletionTimeline(tasks: [Task]) {
                let calendar = Calendar.current
                let today = Date()
                
                // 週間データの計算
                if let weekStart = today.startOfWeek {
                    var weeklyData: [DailyCompletion] = []
                    
                    for day in 0..<7 {
                        if let date = calendar.date(byAdding: .day, value: day, to: weekStart) {
                            let dayStart = calendar.startOfDay(for: date)
                            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                            
                            let completedTasksForDay = tasks.filter { task in
                                if let completionDate = task.completionDate {
                                    return completionDate >= dayStart && completionDate < dayEnd
                                }
                                return false
                            }
                            
                            weeklyData.append(DailyCompletion(
                                day: day,
                                date: date,
                                count: completedTasksForDay.count
                            ))
                        }
                    }
                    
                    weeklyCompletions = weeklyData
                }
                
                // 月間データの計算
                if let monthStart = today.startOfMonth {
                    var monthlyData: [DailyCompletion] = []
                    
                    let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
                    
                    for day in 0..<daysInMonth {
                        if let date = calendar.date(byAdding: .day, value: day, to: monthStart) {
                            let dayStart = calendar.startOfDay(for: date)
                            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                            
                            let completedTasksForDay = tasks.filter { task in
                                if let completionDate = task.completionDate {
                                    return completionDate >= dayStart && completionDate < dayEnd
                                }
                                return false
                            }
                            
                            monthlyData.append(DailyCompletion(
                                day: day + 1, // 1から始まる日付
                                date: date,
                                count: completedTasksForDay.count
                            ))
                        }
                    }
                    
                    monthlyCompletions = monthlyData
                }
            }
        }
