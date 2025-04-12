import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showingNewTaskSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    // 上部のサマリーカード
                    summaryCard
                    
                    // 今日のタスク
                    if !homeViewModel.todayTasks.isEmpty {
                        sectionCard(
                            title: "今日のタスク",
                            destination: AnyView(TaskListView(initialFilter: .today)),
                            content: AnyView(
                                VStack(spacing: DesignSystem.Spacing.s) {
                                    ForEach(homeViewModel.todayTasks.prefix(3)) { task in
                                        SimpleTaskRowView(task: task)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 高優先度タスク
                    if !homeViewModel.priorityTasks.isEmpty {
                        sectionCard(
                            title: "高優先度タスク",
                            destination: AnyView(TaskListView(initialFilter: .highPriority)),
                            content: AnyView(
                                VStack(spacing: DesignSystem.Spacing.s) {
                                    ForEach(homeViewModel.priorityTasks.prefix(3)) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 期限切れタスク
                    if !homeViewModel.overdueTasks.isEmpty {
                        sectionCard(
                            title: "期限切れのタスク",
                            destination: AnyView(TaskListView(initialFilter: .overdue)),
                            content: AnyView(
                                VStack(spacing: DesignSystem.Spacing.s) {
                                    ForEach(homeViewModel.overdueTasks.prefix(3)) { task in
                                        TaskRow(task: task)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 進行中のプロジェクト
                    if !homeViewModel.activeProjects.isEmpty {
                        sectionCard(
                            title: "進行中のプロジェクト",
                            destination: AnyView(ProjectListView()),
                            content: AnyView(
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DesignSystem.Spacing.m) {
                                        ForEach(homeViewModel.activeProjects.prefix(3)) { project in
                                            SimpleProjectCardView(project: project)
                                                .frame(width: 160, height: 100)
                                        }
                                    }
                                }
                            )
                        )
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.l)
                }
                .padding(.horizontal)
                .padding(.top)
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
            }
        }
    }
    
    // シンプルなタスク行
    private struct TaskRow: View {
        @State var task: TMTask
        @EnvironmentObject var taskViewModel: TaskViewModel
        @EnvironmentObject var projectViewModel: ProjectViewModel
        @State private var isCompleted: Bool
        
        init(task: TMTask) {
            self._task = State(initialValue: task)
            self._isCompleted = State(initialValue: task.status == .completed)
        }
        
        var body: some View {
            HStack(spacing: DesignSystem.Spacing.m) {
                // 完了チェックボックス
                Button(action: {
                    isCompleted.toggle()
                    taskViewModel.toggleTaskCompletion(task)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                }
                
                // タスク情報
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    // タスクタイトル
                    Text(task.title)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isCompleted ? .regular : .medium))
                        .foregroundColor(isCompleted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .strikethrough(isCompleted)
                        .lineLimit(1)
                    
                    HStack(spacing: DesignSystem.Spacing.s) {
                        // 優先度マーク
                        Circle()
                            .fill(Color.priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        
                        // プロジェクト
                        if let projectId = task.projectId, let project = projectViewModel.getProject(by: projectId) {
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                Circle()
                                    .fill(project.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(project.name)
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 期限日
                if let dueDate = task.dueDate {
                    Text(dueDate.relativeDisplay)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(taskViewModel.dueDateColor(for: task))
                }
            }
            .padding(DesignSystem.Spacing.s)
        }
    }
    
    // セクションカード共通部分
    private func sectionCard<Destination: View, Content: View>(
        title: String,
        destination: Destination,
        content: Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: destination) {
                    Text("すべて見る")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            content
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // 上部のサマリーカード
    private var summaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            HStack(spacing: DesignSystem.Spacing.l) {
                // 完了率
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("完了率")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(Int(homeViewModel.statistics.completionRate * 100))%")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title1, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                // 今週の完了タスク
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("今週の完了")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(homeViewModel.statistics.tasksCompletedThisWeek)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title1, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            HStack {
                StatCardSimple(
                    title: "今日",
                    value: "\(homeViewModel.todayTasks.count)",
                    iconName: "calendar",
                    color: DesignSystem.Colors.primary
                )
                
                StatCardSimple(
                    title: "高優先",
                    value: "\(homeViewModel.priorityTasks.count)",
                    iconName: "exclamationmark.triangle",
                    color: DesignSystem.Colors.error
                )
                
                StatCardSimple(
                    title: "期限切れ",
                    value: "\(homeViewModel.overdueTasks.count)",
                    iconName: "clock",
                    color: DesignSystem.Colors.warning
                )
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // シンプルなプロジェクトカード
    private struct SimpleProjectCardView: View {
        var project: TMProject
        @EnvironmentObject var taskViewModel: TaskViewModel
        @EnvironmentObject var projectViewModel: ProjectViewModel
        
        var body: some View {
            NavigationLink(destination: ProjectDetailView(project: getProjectFromTMProject(project))) {
                VStack(alignment: .leading, spacing: 5) {
                    // プロジェクト名
                    Text(project.name)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // タスク数
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 12))
                        
                        Text("\(project.taskIds.count) タスク")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    // 進捗バー
                    let progress = projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks)
                    ProgressBarView(value: progress, color: project.color, height: 6)
                }
                .padding()
                .background(DesignSystem.Colors.card)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(project.color, lineWidth: 2)
                )
            }
        }
        
        // TMProjectからProjectに変換するヘルパーメソッド
        private func getProjectFromTMProject(_ tmProject: TMProject) -> Project {
            if let coreDataProject = DataService.shared.getProject(by: tmProject.id) {
                return coreDataProject
            } else {
                let newProject = Project(context: DataService.shared.viewContext)
                newProject.id = tmProject.id
                newProject.name = tmProject.name
                newProject.projectDescription = tmProject.description
                newProject.colorHex = tmProject.colorHex
                newProject.creationDate = tmProject.creationDate
                newProject.dueDate = tmProject.dueDate
                newProject.completionDate = tmProject.completionDate
                return newProject
            }
        }
    }
    
    // シンプルな統計カード
    private struct StatCardSimple: View {
        var title: String
        var value: String
        var iconName: String
        var color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(value)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.s)
            .background(color.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)
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
