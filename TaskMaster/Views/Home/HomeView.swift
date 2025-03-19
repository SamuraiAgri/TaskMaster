import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingNewTaskSheet = false
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // 上部のサマリーカード
                    summaryCard
                    
                    // 今日のタスク
                    if !homeViewModel.todayTasks.isEmpty {
                        TodayTasksView(tasks: homeViewModel.todayTasks)
                    }
                    
                    // 高優先度タスク
                    if !homeViewModel.priorityTasks.isEmpty {
                        PriorityTasksView(tasks: homeViewModel.priorityTasks)
                    }
                    
                    // 期限切れタスク
                    if !homeViewModel.overdueTasks.isEmpty {
                        OverdueTasksView(tasks: homeViewModel.overdueTasks)
                    }
                    
                    // 進行中のプロジェクト
                    if !homeViewModel.activeProjects.isEmpty {
                        activeProjectsSection
                    }
                    
                    // 今後のタスク
                    if !homeViewModel.upcomingTasks.isEmpty {
                        upcomingTasksSection
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("ホーム")
            .navigationBarItems(
                trailing: Button(action: {
                    showingNewTaskSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            )
            .sheet(isPresented: $showingNewTaskSheet) {
                TaskCreationView()
            }
            .onAppear {
                homeViewModel.loadData()
            }
            .refreshable {
                homeViewModel.loadData()
                refreshTrigger.toggle()
            }
        }
    }
    
    // 上部のサマリーカード
    private var summaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("タスク完了率")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(Int(homeViewModel.statistics.completionRate * 100))%")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title1, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("今週の完了タスク")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(homeViewModel.statistics.tasksCompletedThisWeek)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title1, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            // 週間タスク完了グラフ
            weeklyCompletionChart
            
            HStack {
                StatCard(
                    title: "今日",
                    value: "\(homeViewModel.todayTasks.count)",
                    iconName: "calendar",
                    color: DesignSystem.Colors.primary
                )
                
                StatCard(
                    title: "高優先",
                    value: "\(homeViewModel.priorityTasks.count)",
                    iconName: "exclamationmark.triangle",
                    color: DesignSystem.Colors.error
                )
                
                StatCard(
                    title: "期限切れ",
                    value: "\(homeViewModel.overdueTasks.count)",
                    iconName: "clock",
                    color: DesignSystem.Colors.warning
                )
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .withShadow(DesignSystem.Shadow.medium)
    }
    
    // 週間タスク完了グラフ
    private var weeklyCompletionChart: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<7, id: \.self) { index in
                let value = homeViewModel.statistics.dailyCompletions[index]
                let maxValue = homeViewModel.statistics.dailyCompletions.max() ?? 1
                
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    // バー
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(getDayColor(index))
                        .frame(
                            width: (UIScreen.main.bounds.width - 70) / 7 - DesignSystem.Spacing.xs,
                            height: value > 0 ? CGFloat(value) / CGFloat(maxValue) * 100 : 5
                        )
                    
                    // 曜日ラベル
                    Text(getDayLabel(index))
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(height: 120)
        .padding(.vertical, DesignSystem.Spacing.s)
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
    
    // 進行中のプロジェクトセクション
    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("進行中のプロジェクト")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: ProjectListView()) {
                    Text("すべて見る")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    ForEach(homeViewModel.activeProjects.prefix(5)) { project in
                        ProjectCardView(project: project)
                            .frame(width: 180, height: 140)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.s)
            }
        }
    }
    
    // 今後のタスクセクション
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("今後のタスク")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: TaskListView()) {
                    Text("すべて見る")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(homeViewModel.upcomingTasks.prefix(5)) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }
}

// 統計カード
struct StatCard: View {
    var title: String
    var value: String
    var iconName: String
    var color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.s)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// プロジェクトカード
struct ProjectCardView: View {
    var project: Project
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        NavigationLink(destination: ProjectDetailView(project: project)) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                // プロジェクト名
                Text(project.name)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // タスク数
                HStack {
                    Image(systemName: "checklist")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(project.taskIds.count) タスク")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // 期限日
                if let dueDate = project.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(dueDate.formatted())
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                // 進捗状況バー
                let progress = projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks)
                ProgressBarView(value: progress, color: project.color)
            }
            .padding()
            .background(DesignSystem.Colors.card)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .withShadow(DesignSystem.Shadow.small)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(project.color, lineWidth: 2)
            )
        }
    }
}

// プレビュー
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HomeViewModel())
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
    }
}
