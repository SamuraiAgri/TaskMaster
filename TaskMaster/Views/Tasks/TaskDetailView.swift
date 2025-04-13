import SwiftUI

struct TaskDetailView: View {
    var taskId: UUID
    @State private var tmTask: TMTask?
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var tags: [TMTag] = []
    @State private var project: TMProject?
    
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            if let task = tmTask {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // タスク情報
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        // タイトルと優先度
                        HStack {
                            Text(task.title)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title3, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            PriorityBadgeView(priority: task.priority)
                        }
                        
                        // ステータスと期限日
                        HStack {
                            Text(task.status.rawValue)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .padding(.horizontal, DesignSystem.Spacing.s)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(Color.statusColor(task.status).opacity(0.2))
                                .foregroundColor(Color.statusColor(task.status))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            
                            Spacer()
                            
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
                        }
                        
                        // 繰り返し情報（繰り返しタスクの場合）
                        if task.isRepeating {
                            HStack {
                                if task.repeatType == .custom, let customValue = task.repeatCustomValue {
                                    CustomRepeatIndicator(repeatValue: customValue)
                                } else {
                                    RepeatIndicator(repeatType: task.repeatType)
                                }
                                
                                Spacer()
                                
                                Text(getRepeatDescription(task))
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                        
                        // 完了ボタン
                        Button(action: {
                            taskViewModel.toggleTaskCompletion(task)
                            
                            // State更新
                            loadTaskDetails()
                        }) {
                            HStack {
                                Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                Text(task.isCompleted ? "未完了に戻す" : "完了にする")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(task.isCompleted ? DesignSystem.Colors.warning.opacity(0.2) : DesignSystem.Colors.success.opacity(0.2))
                            .foregroundColor(task.isCompleted ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    
                    // 詳細
                    if let description = task.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("詳細")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(description)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.card)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // プロジェクト情報
                    if let project = project {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("プロジェクト")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            NavigationLink(destination: ProjectDetailView(project: getProjectFromTMProject(project))) {
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
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(DesignSystem.Colors.card)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // タグ情報
                    if !tags.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("タグ")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            TagsListView(tags: tags)
                        }
                        .padding()
                        .background(DesignSystem.Colors.card)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // その他のメタデータ
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("情報")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // 作成日
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("作成日: \(task.creationDate.formatted())")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        // 完了日（あれば）
                        if let completionDate = task.completionDate {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(DesignSystem.Colors.success)
                                
                                Text("完了日: \(completionDate.formatted())")
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding()
            } else {
                // ローディング表示
                VStack {
                    ProgressView()
                    Text("読み込み中...")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .navigationTitle("タスク詳細")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack {
                if tmTask != nil {
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
            if let task = tmTask {
                SimpleTaskEditView(task: task) { updatedTask in
                    self.tmTask = updatedTask
                    loadTaskDetails()
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("タスクの削除"),
                message: Text("このタスクを削除しますか？この操作は元に戻せません。"),
                primaryButton: .destructive(Text("削除")) {
                    if let task = tmTask {
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
    
    // 繰り返しの説明文を取得
    private func getRepeatDescription(_ task: TMTask) -> String {
        if !task.isRepeating {
            return ""
        }
        
        switch task.repeatType {
        case .none:
            return ""
        case .daily:
            return "毎日繰り返し"
        case .weekdays:
            return "平日（月-金）繰り返し"
        case .weekly:
            return "毎週繰り返し"
        case .monthly:
            return "毎月繰り返し"
        case .yearly:
            return "毎年繰り返し"
        case .custom:
            if let value = task.repeatCustomValue {
                if value % 30 == 0 {
                    let months = value / 30
                    return months == 1 ? "毎月繰り返し" : "\(months)ヶ月ごとに繰り返し"
                } else if value % 7 == 0 {
                    let weeks = value / 7
                    return weeks == 1 ? "毎週繰り返し" : "\(weeks)週間ごとに繰り返し"
                } else {
                    return value == 1 ? "毎日繰り返し" : "\(value)日ごとに繰り返し"
                }
            }
            return "カスタム繰り返し"
        }
    }
    
    // タスクとその関連情報を読み込む
    private func loadTaskDetails() {
        tmTask = taskViewModel.getTask(by: taskId)
        
        if let task = tmTask {
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
    
    // TMProjectからProjectに変換するヘルパーメソッド
    private func getProjectFromTMProject(_ tmProject: TMProject) -> Project {
        if let coreDataProject = DataService.shared.getProject(by: tmProject.id) {
            return coreDataProject
        } else {
            // 実際のプロジェクトが見つからない場合のフォールバック
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
