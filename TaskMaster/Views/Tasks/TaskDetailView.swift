import SwiftUI

struct TaskDetailView: View {
    var taskId: UUID
    @State private var task: Task?
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var tags: [Tag] = []
    @State private var project: Project?
    
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            if let task = task {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    // ヘッダー情報
                    taskHeader(task: task)
                    
                    Divider()
                    
                    // タスクの詳細情報
                    taskDetails(task: task)
                    
                    // プロジェクト情報
                    if let project = project {
                        projectSection(project: project)
                    }
                    
                    // タグ情報
                    if !tags.isEmpty {
                        tagsSection(tags: tags)
                    }
                    
                    // サブタスク（将来的に実装）
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack {
                    ProgressView()
                    Text("タスクを読み込み中...")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .navigationTitle(task?.title ?? "タスク詳細")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack {
                if let task = task {
                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
        )
        .sheet(isPresented: $isEditing) {
            if let task = task {
                NavigationView {
                    TaskEditView(task: task) { updatedTask in
                        self.task = updatedTask
                        loadTaskDetails()
                    }
                    .navigationTitle("タスクの編集")
                    .navigationBarItems(trailing: Button("完了") {
                        isEditing = false
                    })
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("タスクの削除"),
                message: Text("本当にこのタスクを削除しますか？この操作は元に戻せません。"),
                primaryButton: .destructive(Text("削除")) {
                    if let task = task {
                        taskViewModel.deleteTask(id: task.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .onAppear {
            loadTaskDetails()
        }
        .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
    }
    
    // タスクとその関連情報を読み込む
    private func loadTaskDetails() {
        task = taskViewModel.getTask(by: taskId)
        
        if let task = task {
            // プロジェクト情報を取得
            if let projectId = task.projectId {
                project = projectViewModel.getProject(by: projectId)
            } else {
                project = nil
            }
            
            // タグ情報を取得
            tags = tagViewModel.getTags(by: task.tagIds)
        }
    }
    
    // タスクヘッダー
    private func taskHeader(task: Task) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                // ステータス表示
                Text(task.status.rawValue)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                    .padding(.horizontal, DesignSystem.Spacing.s)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(Color.statusColor(task.status).opacity(0.2))
                    .foregroundColor(Color.statusColor(task.status))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                
                Spacer()
                
                // 優先度表示
                PriorityBadgeView(priority: task.priority)
            }
            
            // タイトル
            Text(task.title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title2, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // 期限と作成日
            HStack(spacing: DesignSystem.Spacing.l) {
                if let dueDate = task.dueDate {
                    Label {
                        Text(dueDate.formatted())
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(taskViewModel.dueDateColor(for: task))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(taskViewModel.dueDateColor(for: task))
                    }
                }
                
                Label {
                    Text(task.creationDate.formatted())
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } icon: {
                    Image(systemName: "clock")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            // 完了ボタン
            Button(action: {
                var updatedTask = task
                taskViewModel.toggleTaskCompletion(updatedTask)
                
                // State更新
                self.task = taskViewModel.getTask(by: taskId)
            }) {
                HStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    Text(task.isCompleted ? "完了を取り消す" : "完了にする")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isCompleted ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.primary.opacity(0.1))
                .foregroundColor(task.isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
    }
    
    // タスク詳細
    private func taskDetails(task: Task) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            // セクションタイトル
            Text("詳細")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // 説明文
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            } else {
                Text("説明はありません")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .italic()
            }
            
            // リマインダー
            if let reminderDate = task.reminderDate {
                detailRow(icon: "bell", title: "リマインダー", value: reminderDate.formatted(style: .medium, showTime: true))
            }
            
            // 繰り返し設定
            if task.isRepeating {
                detailRow(icon: "repeat", title: "繰り返し", value: task.repeatType.rawValue)
            }
            
            // 完了日
            if let completionDate = task.completionDate {
                detailRow(icon: "checkmark.circle", title: "完了日", value: completionDate.formatted())
            }
        }
    }
    
    // プロジェクトセクション
    private func projectSection(project: Project) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("プロジェクト")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            NavigationLink(destination: ProjectDetailView(project: project)) {
                HStack {
                    Circle()
                        .fill(project.color)
                        .frame(width: 12, height: 12)
                    
                    Text(project.name)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding()
                .background(DesignSystem.Colors.card)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
    }
    
    // タグセクション
    private func tagsSection(tags: [Tag]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("タグ")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            TagsListView(tags: tags)
                .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
    
    // 詳細行
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// 優先度バッジビュー
struct PriorityBadgeView: View {
    var priority: Priority
    var showText: Bool = true
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(Color.priorityColor(priority))
                .frame(width: 8, height: 8)
            
            if showText {
                Text(priority.title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(Color.priorityColor(priority))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.s)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(Color.priorityColor(priority).opacity(0.2))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// プレビュー
struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(taskId: Task.samples[0].id)
                .environmentObject(TaskViewModel())
                .environmentObject(ProjectViewModel())
                .environmentObject(TagViewModel())
        }
    }
}
