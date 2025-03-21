import SwiftUI

struct TaskListView: View {
    // 環境変数
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    
    // UI制御プロパティ
    @State private var showingFilterSheet = false
    @State private var showingNewTaskSheet = false
    @State private var showingSortOptions = false
    @State private var showingSearchBar = false
    @State private var refreshTrigger = false
    
    // 初期フィルター
    var initialFilter: TaskFilter?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索・フィルターバー
                if showingSearchBar {
                    searchFilterBar
                }
                
                // タスクリスト
                if taskViewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListContent
                }
            }
            .navigationTitle("タスク")
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        showingSearchBar.toggle()
                    }) {
                        Image(systemName: showingSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle\(taskViewModel.selectedFilter != .all ? ".fill" : "")")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(taskViewModel.selectedFilter.title)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                .lineLimit(1)
                        }
                    }
                },
                trailing: Button(action: {
                    showingNewTaskSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            )
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(
                    title: Text("フィルター"),
                    buttons: [
                        .default(Text("すべてのタスク")) { taskViewModel.selectedFilter = .all },
                        .default(Text("今日のタスク")) { taskViewModel.selectedFilter = .today },
                        .default(Text("予定されたタスク")) { taskViewModel.selectedFilter = .upcoming },
                        .default(Text("期限切れのタスク")) { taskViewModel.selectedFilter = .overdue },
                        .default(Text("完了したタスク")) { taskViewModel.selectedFilter = .completed },
                        .default(Text("高優先度タスク")) { taskViewModel.selectedFilter = .highPriority },
                        .cancel(Text("キャンセル"))
                    ]
                )
            }
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
    
    // 検索フィルターバー
    private var searchFilterBar: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("タスクを検索", text: $taskViewModel.searchText)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                
                if !taskViewModel.searchText.isEmpty {
                    Button(action: {
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
            
            // ソートオプション
            HStack {
                Text("並び替え:")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Button(action: {
                    showingSortOptions = true
                }) {
                    HStack {
                        Text(taskViewModel.selectedSortOption.title)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    taskViewModel.isAscending.toggle()
                }) {
                    Image(systemName: taskViewModel.isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, DesignSystem.Spacing.xs)
                            .actionSheet(isPresented: $showingSortOptions) {
                ActionSheet(
                    title: Text("並び替え"),
                    buttons: [
                        .default(Text("期限日")) { taskViewModel.selectedSortOption = .dueDate },
                        .default(Text("優先度")) { taskViewModel.selectedSortOption = .priority },
                        .default(Text("タイトル")) { taskViewModel.selectedSortOption = .title },
                        .default(Text("作成日")) { taskViewModel.selectedSortOption = .creationDate },
                        .default(Text("完了日")) { taskViewModel.selectedSortOption = .completionDate },
                        .cancel(Text("キャンセル"))
                    ]
                )
            }
        }
        .padding(.horizontal)
        .background(DesignSystem.Colors.background)
    }
    
    // タスクリスト（タスクがある場合）
    private var taskListContent: some View {
        List {
            ForEach(taskViewModel.filteredTasks) { tmTask in
                NavigationLink(destination: TaskDetailView(taskId: tmTask.id)) {
                    TaskRowView(task: tmTask)
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
            refreshTrigger.toggle()
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

// タスク行ビュー
struct TaskRowView: View {
    @State var task: TMTask
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
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
                    // 優先度
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Circle()
                            .fill(Color.priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        
                        Text(task.priority.title)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
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
                    
                    // タグ（一つだけ表示）
                    if !task.tagIds.isEmpty, let tagId = task.tagIds.first, let tag = tagViewModel.getTag(by: tagId) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 8, height: 8)
                            
                            Text(tag.name)
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
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    Text(dueDate.relativeDisplay)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(taskViewModel.dueDateColor(for: task))
                    
                    // 繰り返しタスクマーク
                    if task.isRepeating {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.s)
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
