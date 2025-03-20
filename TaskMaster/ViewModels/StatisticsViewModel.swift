import Foundation
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    // 公開プロパティ
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
        let totalTasks = allTasks.count
        
        // 完了タスク数
        let completedTasks = tasks.filter { $0.completionDate != nil }
        let completedTasksCount = completedTasks.count
        
        // 完了率
        let completionRate = tasks.isEmpty ? 0 : Double(completedTasksCount) / Double(tasks.count)
        
        // 期限内に完了したタスク数
        let tasksCompletedOnTime = completedTasks.filter { task in
            if let dueDate = task.dueDate, let completionDate = task.completionDate {
                return completionDate <= dueDate
            }
            return false
        }
        let tasksCompletedOnTimeCount = tasksCompletedOnTime.count
        
        // 期限内完了率
        let onTimeCompletionRate = completedTasks.isEmpty ? 0 : Double(tasksCompletedOnTimeCount) / Double(completedTasksCount)
        
        // 優先度別タスク数
        let highPriorityTasks = tasks.filter { Int(task.priority) == 3 }.count
        let mediumPriorityTasks = tasks.filter { Int(task.priority) == 2 }.count
        let lowPriorityTasks = tasks.filter { Int(task.priority) == 1 }.count
        
        // 週間データの計算
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        
        // 週の始まりを月曜日にする調整
        let daysToMonday = weekday == 1 ? -6 : -(weekday - 2)
        
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
            
            let tasksCompletedThisWeekCount = thisWeekCompletedTasks.count
            
            // 曜日別の完了タスク数
            var dayCompletions = [Int](repeating: 0, count: 7)
            
            for task in thisWeekCompletedTasks {
                if let completionDate = task.completionDate {
                    let weekdayIndex = calendar.component(.weekday, from: completionDate)
                    // 配列に合わせて調整（0=月曜日, 1=火曜日, ..., 6=日曜日）
                    let adjustedIndex = (weekdayIndex + 5) % 7
                    dayCompletions[adjustedIndex] += 1
                }
            }
            
            // 値を更新
            self.weeklyCompletions = dayCompletions.enumerated().map { (index, count) in
                DailyCompletion(
                    day: index,
                    date: calendar.date(byAdding: .day, value: index, to: monday) ?? Date(),
                    count: count
                )
            }
        }
        
        // アクティブなプロジェクト数
        let activeProjectsCount = projects.filter { $0.completionDate == nil }.count
        
        // 完了したプロジェクト数
        let completedProjectsCount = projects.filter { $0.completionDate != nil }.count
        
        // 使用中のタグ数
        let activeTagsCount = tags.count
    }
    
    /// プロジェクトの進捗状況を計算
    private func calculateProjectsProgress(tasks: [Task], projects: [Project]) {
        var progress: [ProjectProgress] = []
        
        for project in projects {
            let projectTasks = tasks.filter { task in
                task.project?.id == project.id
            }
            
            if !projectTasks.isEmpty {
                let completedTasks = projectTasks.filter { $0.completionDate != nil }.count
                let progressValue = Double(completedTasks) / Double(projectTasks.count)
                
                progress.append(ProjectProgress(
                    id: project.id ?? UUID(),
                    name: project.name ?? "",
                    progress: progressValue,
                    color: Color(hex: project.colorHex ?? "#4A90E2") ?? .blue,
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
                task.tags?.contains(tag) ?? false
            }
            
            if !taggedTasks.isEmpty {
                distribution.append(TagsDistribution(
                    id: tag.id ?? UUID(),
                    name: tag.name ?? "",
                    count: taggedTasks.count,
                    color: Color(hex: tag.colorHex ?? "#AAAAAA") ?? .gray
                ))
            }
        }
        
        // タスク数でソート（降順）
        tagsDistribution = distribution.sorted { $0.count > $1.count }
    }
    
    /// 優先度の分布を計算
    private func calculatePriorityDistribution(tasks: [Task]) {
        let high = tasks.filter { Int(task.priority) == 3 }.count
        let medium = tasks.filter { Int(task.priority) == 2 }.count
        let low = tasks.filter { Int(task.priority) == 1 }.count
        
        priorityDistribution = [
            PriorityDistribution(priority: .high, count: high, color: DesignSystem.Colors.error),
            PriorityDistribution(priority: .medium, count: medium, color: DesignSystem.Colors.warning),
            PriorityDistribution(priority: .low, count: low, color: DesignSystem.Colors.info)
        ]
    }
    
    /// ステータスの分布を計算
    private func calculateStatusDistribution(tasks: [Task]) {
        let notStarted = tasks.filter { task.status == "未着手" }.count
        let inProgress = tasks.filter { task.status == "進行中" }.count
        let completed = tasks.filter { task.status == "完了" }.count
        let postponed = tasks.filter { task.status == "延期" }.count
        let cancelled = tasks.filter { task.status == "キャンセル" }.count
        
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
