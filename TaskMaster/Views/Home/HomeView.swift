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
                                        SimpleTaskRowView(task: task)
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
                                        SimpleTaskRowView(task: task)
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
