import SwiftUI

struct StatisticsView: View {
    // 環境変数
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    // ステート
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingTasksCompleted = false
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // 期間選択セグメント
                    Picker("期間", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.title)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // タスク完了率カード
                    completionRateCard
                    
                    // タスク統計カード
                    taskStatsCard
                    
                    // 優先度分布
                    priorityDistributionCard
                    
                    // 週間活動チャート
                    weeklyActivityCard
                    
                    // プロジェクト進捗
                    projectProgressCard
                }
                .padding(.vertical)
            }
            .navigationTitle("統計")
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .onAppear {
                homeViewModel.loadData()
            }
            .refreshable {
                homeViewModel.loadData()
                refreshTrigger.toggle()
            }
        }
    }
    
    // タスク完了率カード
    private var completionRateCard: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("タスク完了率")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showingTasksCompleted.toggle()
                }) {
                    Text(showingTasksCompleted ? "今週" : "全体")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if showingTasksCompleted {
                PieChartView(
                    value: Double(homeViewModel.statistics.tasksCompletedThisWeek),
                    total: Double(homeViewModel.statistics.totalTasks),
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 180)
                
                VStack {
                    Text("\(homeViewModel.statistics.tasksCompletedThisWeek)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title1, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("今週完了したタスク")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                PieChartView(
                    value: Double(homeViewModel.statistics.completedTasks),
                    total: Double(homeViewModel.statistics.totalTasks),
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 180)
                
                HStack(spacing: DesignSystem.Spacing.l) {
                    VStack {
                        Text("\(homeViewModel.statistics.completedTasks)")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title2, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("完了")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    VStack {
                        Text("\(homeViewModel.statistics.totalTasks - homeViewModel.statistics.completedTasks)")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title2, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("未完了")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    VStack {
                        Text("\(homeViewModel.statistics.totalTasks)")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title2, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("合計")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: DesignSystem.Shadows.medium.color, radius: DesignSystem.Shadows.medium.radius, x: DesignSystem.Shadows.medium.x, y: DesignSystem.Shadows.medium.y)
        .padding(.horizontal)
    }
    
    // タスク統計カード
    private var taskStatsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("タスク統計")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack {
                StatCardSquare(
                    title: "期限内完了率",
                    value: "\(Int(homeViewModel.statistics.onTimeCompletionRate * 100))%",
                    iconName: "clock",
                    color: DesignSystem.Colors.success
                )
                
                StatCardSquare(
                    title: "活動プロジェクト",
                    value: "\(homeViewModel.statistics.activeProjects)",
                    iconName: "folder",
                    color: DesignSystem.Colors.primary
                )
                
                StatCardSquare(
                    title: "期限切れタスク",
                    value: "\(homeViewModel.overdueTasks.count)",
                    iconName: "exclamationmark.triangle",
                    color: DesignSystem.Colors.error
                )
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: DesignSystem.Shadows.small.color, radius: DesignSystem.Shadows.small.radius, x: DesignSystem.Shadows.small.x, y: DesignSystem.Shadows.small.y)
        .padding(.horizontal)
    }
    
    // 優先度分布カード
    private var priorityDistributionCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("優先度分布")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.l) {
                // 高優先度
                BarChartItem(
                    value: homeViewModel.statistics.highPriorityTasks,
                    total: homeViewModel.statistics.totalTasks,
                    title: "高",
                    color: DesignSystem.Colors.error
                )
                
                // 中優先度
                BarChartItem(
                    value: homeViewModel.statistics.mediumPriorityTasks,
                    total: homeViewModel.statistics.totalTasks,
                    title: "中",
                    color: DesignSystem.Colors.warning
                )
                
                // 低優先度
                BarChartItem(
                    value: homeViewModel.statistics.lowPriorityTasks,
                    total: homeViewModel.statistics.totalTasks,
                    title: "低",
                    color: DesignSystem.Colors.info
                )
            }
            .frame(height: 150)
            .padding(.top, DesignSystem.Spacing.s)
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: DesignSystem.Shadows.small.color, radius: DesignSystem.Shadows.small.radius, x: DesignSystem.Shadows.small.x, y: DesignSystem.Shadows.small.y)
        .padding(.horizontal)
    }
    
    // 週間活動チャートカード
    private var weeklyActivityCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("週間タスク完了実績")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // 週間活動チャート用のデータ準備
            let weeklyData = prepareWeeklyChartData()
            
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<7, id: \.self) { index in
                    let value = weeklyData.values[index]
                    let maxValue = weeklyData.maxValue
                    
                    VStack(spacing: DesignSystem.Spacing.xxs) {
                        // バー
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(weeklyData.colors[index])
                            .frame(
                                width: (UIScreen.main.bounds.width - 100) / 7 - DesignSystem.Spacing.xs,
                                height: value > 0 ? CGFloat(value) / CGFloat(maxValue > 0 ? maxValue : 1) * 120 : 5
                            )
                        
                        // 数値
                        Text("\(value)")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // 曜日ラベル
                        Text(weeklyData.labels[index])
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .frame(height: 150)
            .padding(.top, DesignSystem.Spacing.s)
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: DesignSystem.Shadows.small.color, radius: DesignSystem.Shadows.small.radius, x: DesignSystem.Shadows.small.x, y: DesignSystem.Shadows.small.y)
        .padding(.horizontal)
    }
    
    // 週間チャートデータの準備
    private func prepareWeeklyChartData() -> (values: [Int], maxValue: Int, labels: [String], colors: [Color]) {
        let values = homeViewModel.statistics.dailyCompletions
        let maxValue = values.max() ?? 1
        let labels = (0..<7).map { getDayLabel($0) }
        let colors = (0..<7).map { getDayColor($0) }
        
        return (values: values, maxValue: maxValue, labels: labels, colors: colors)
    }
    
    // プロジェクト進捗カード
    private var projectProgressCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("プロジェクト進捗")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if homeViewModel.activeProjects.isEmpty {
                Text("アクティブなプロジェクトがありません")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(0..<min(homeViewModel.activeProjects.count, 5), id: \.self) { index in
                    let project = homeViewModel.activeProjects[index]
                    ProjectProgressItemView(project: project)
                }
                
                if homeViewModel.activeProjects.count > 5 {
                    Button(action: {
                        // ナビゲーションへのリンクはここに実装
                    }) {
                        Text("すべてのプロジェクトを表示...")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: DesignSystem.Shadows.small.color, radius: DesignSystem.Shadows.small.radius, x: DesignSystem.Shadows.small.x, y: DesignSystem.Shadows.small.y)
        .padding(.horizontal)
    }
    
    // プロジェクト進捗アイテム
    private struct ProjectProgressItemView: View {
        var project: TMProject
        @EnvironmentObject var taskViewModel: TaskViewModel
        @EnvironmentObject var projectViewModel: ProjectViewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text(project.name)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    let progress = projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks)
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ProgressBarView(value: projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks), color: project.color, height: 8)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
    
    // 曜日ラベルの取得
    private func getDayLabel(_ index: Int) -> String {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        return days[index]
    }
    
    // 曜日の色取得
    private func getDayColor(_ index: Int) -> Color {
        let today = Calendar.current.component(.weekday, from: Date())
        // 日曜日=1, 月曜日=2, ..., 土曜日=7
        let todayAdjusted = today == 1 ? 6 : today - 2 // 月曜日=0, 火曜日=1, ..., 日曜日=6
        
        return index == todayAdjusted ? DesignSystem.Colors.accent : DesignSystem.Colors.primary
    }
}

// 時間枠
enum TimeFrame: CaseIterable {
    case week
    case month
    case year
    
    var title: String {
        switch self {
        case .week: return "週"
        case .month: return "月"
        case .year: return "年"
        }
    }
}

// 統計用正方形カード
struct StatCardSquare: View {
    var title: String
    var value: String
    var iconName: String
    var color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title3, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.m)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// 円グラフビュー
struct PieChartView: View {
    var value: Double
    var total: Double
    var color: Color
    
    private var percentage: Double {
        total == 0 ? 0 : min(value / total, 1.0)
    }
    
    var body: some View {
        ZStack {
            // 背景円
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 30)
            
            // 進捗円
            Circle()
                .trim(from: 0, to: CGFloat(percentage))
                .stroke(color, lineWidth: 30)
                .rotationEffect(Angle(degrees: -90))
            
            // パーセンテージ表示
            VStack {
                Text("\(Int(percentage * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.largeTitle, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("達成率")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// 棒グラフアイテム
struct BarChartItem: View {
    var value: Int
    var total: Int
    var title: String
    var color: Color
    
    private var percentage: Double {
        total == 0 ? 0 : min(Double(value) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            // 値
            Text("\(value)")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // バー
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(color)
                .frame(width: 40, height: max(CGFloat(percentage) * 100, 5))
            
            // タイトル
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(HomeViewModel())
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
    }
}
