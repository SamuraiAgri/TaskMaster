import SwiftUI

struct TaskListView: View {
    // 環境変数
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    
    // UI制御プロパティ
    @State private var showingFilterSheet = false
    @State private var showingNewTaskSheet = false
    @State private var showingSearchBar = false
    @State private var searchText = ""
    
    // 初期フィルター
    var initialFilter: TaskFilter?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー（表示されている場合）
                if showingSearchBar {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("タスクを検索", text: $searchText)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .onChange(of: searchText) { oldValue, newValue in
                                taskViewModel.searchText = newValue
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                taskViewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .padding([.horizontal, .top])
                }
                
                // フィルターチップ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.m) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.title,
                                isSelected: taskViewModel.selectedFilter == filter,
                                action: {
                                    taskViewModel.selectedFilter = filter
                                }
                            )
                        }
                    }
                    .padding([.horizontal, .vertical])
                }
                
                // タスクリスト
                if taskViewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(taskViewModel.filteredTasks) { tmTask in
                            NavigationLink(destination: TaskDetailView(taskId: tmTask.id)) {
                                SimpleTaskRowView(task: tmTask)
                            }
                            .listRowBackground(DesignSystem.Colors.card)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete(perform: taskViewModel.deleteTask)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        taskViewModel.loadTasks()
                    }
                }
            }
            .navigationTitle("タスク")
            .navigationBarItems(
                leading: Button(action: {
                    showingSearchBar.toggle()
                }) {
                    Image(systemName: showingSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                },
                trailing: Button(action: {
                    showingNewTaskSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            )
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingNewTaskSheet) {
                TaskCreationView()
            }
            .onAppear {
                // 初期フィルターの設定
                if let initialFilter = initialFilter {
                    taskViewModel.selectedFilter = initialFilter
                }
            }
        }
    }
    
    // 空の状態表示（タスクがない場合）
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            Text(emptyStateMessage)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingNewTaskSheet = true
            }) {
                Text("新しいタスクを作成")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 280)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
    
    // 空の状態メッセージ
    private var emptyStateMessage: String {
        if !taskViewModel.searchText.isEmpty {
            return "「\(taskViewModel.searchText)」に一致するタスクはありません"
        }
        
        switch taskViewModel.selectedFilter {
        case .all:
            return "タスクはまだありません\n新しいタスクを作成しましょう"
        case .today:
            return "今日のタスクはありません"
        case .upcoming:
            return "予定されたタスクはありません"
        case .overdue:
            return "期限切れのタスクはありません\nすべて完了しています！"
        case .completed:
            return "完了したタスクはありません"
        case .highPriority:
            return "高優先度のタスクはありません"
        }
    }
}

// シンプルなタスク行
struct SimpleTaskRowView: View {
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

// フィルターチップ
struct FilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote, weight: isSelected ? .medium : .regular))
                .padding(.horizontal, DesignSystem.Spacing.s)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.card)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
}

// プレビュー
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
    }
}
