import SwiftUI

struct ProjectDetailView: View {
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    // プロジェクト
    var project: Project
    @State private var editedProject: Project
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingNewTaskSheet = false
    @State private var filter: ProjectTaskFilter = .all
    
    // フィルタリングされたタスク
    @State private var filteredTasks: [Task] = []
    
    // 初期化
    init(project: Project) {
        self.project = project
        self._editedProject = State(initialValue: project)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                // プロジェクトヘッダー
                projectHeader
                
                // プロジェクト詳細
                projectDetails
                
                // タスクフィルター
                taskFilterView
                
                // タスクリスト
                taskListView
                
                // 新規タスク追加ボタン
                Button(action: {
                    showingNewTaskSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        
                        Text("新規タスクを追加")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: HStack {
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
        })
        .sheet(isPresented: $isEditing) {
            ProjectEditView(project: editedProject) { updatedProject in
                projectViewModel.updateProject(updatedProject)
                editedProject = updatedProject
            }
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            // プロジェクトを選択した状態で新規タスク作成画面を表示
            TaskCreationViewWithProject(projectId: project.id)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("プロジェクトの削除"),
                message: Text("このプロジェクトを削除しますか？関連するタスクは削除されませんが、プロジェクトとの関連付けは解除されます。"),
                primaryButton: .destructive(Text("削除")) {
                    projectViewModel.deleteProject(id: project.id)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .onAppear {
            loadProjectTasks()
        }
        .onChange(of: filter) { _ in
            filterTasks()
        }
        .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
    }
    
    // プロジェクトヘッダー
    private var projectHeader: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // 進捗バー
            let progress = projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("進捗状況")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                AnimatedProgressBarView(value: progress, color: project.color, height: 10)
            }
            
            // プロジェクト統計
            HStack {
                let projectTasks = taskViewModel.tasks.filter { project.taskIds.contains($0.id) }
                let totalTasks = projectTasks.count
                let completedTasks = projectTasks.filter { $0.isCompleted }.count
                
                StatCard(
                    title: "完了",
                    value: "\(completedTasks)",
                    iconName: "checkmark.circle",
                    color: DesignSystem.Colors.success
                )
                
                StatCard(
                    title: "未完了",
                    value: "\(totalTasks - completedTasks)",
                    iconName: "circle",
                    color: DesignSystem.Colors.warning
                )
                
                StatCard(
                    title: "合計",
                    value: "\(totalTasks)",
                    iconName: "list.bullet",
                    color: project.color
                )
            }
            
            // 完了ボタン
            if project.isCompleted {
                Button(action: {
                    var updatedProject = project
                    updatedProject.completionDate = nil
                    projectViewModel.updateProject(updatedProject)
                    editedProject = updatedProject
                }) {
                    Text("未完了に戻す")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.warning)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            } else {
                Button(action: {
                    var updatedProject = project
                    updatedProject.completionDate = Date()
                    projectViewModel.updateProject(updatedProject)
                    editedProject = updatedProject
                }) {
                    Text("完了にする")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.success)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
    }
    
    // プロジェクト詳細
    private var projectDetails: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            // 説明
            if let description = project.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("説明")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(description)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.card)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding(.horizontal)
            }
            
            // プロジェクト情報
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                Text("プロジェクト情報")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                // カラー
                HStack {
                    Text("カラー:")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Circle()
                        .fill(project.color)
                        .frame(width: 20, height: 20)
                }
                
                // 作成日
                HStack {
                    Text("作成日:")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(project.creationDate.formatted())
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                // 期限日
                if let dueDate = project.dueDate {
                    HStack {
                        Text("期限日:")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(dueDate.formatted())
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(project.isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                    }
                }
                
                // 完了日
                if let completionDate = project.completionDate {
                    HStack {
                        Text("完了日:")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(completionDate.formatted())
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // タスクフィルター
    private var taskFilterView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("タスク一覧")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    ForEach(ProjectTaskFilter.allCases, id: \.self) { filterOption in
                        Button(action: {
                            filter = filterOption
                        }) {
                            Text(filterOption.title)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(filter == filterOption ? .white : DesignSystem.Colors.textPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.m)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(filter == filterOption ? project.color : DesignSystem.Colors.card)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // タスクリスト
    private var taskListView: some View {
        VStack {
            if filteredTasks.isEmpty {
                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                    
                    Text(emptyStateMessage)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: DesignSystem.Spacing.s) {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: TaskDetailView(taskId: task.id)) {
                            TaskRowView(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // 空の状態メッセージ
    private var emptyStateMessage: String {
        switch filter {
        case .all:
            return "このプロジェクトにはまだタスクがありません。\n「新規タスクを追加」から作成しましょう。"
        case .incomplete:
            return "このプロジェクトには未完了のタスクがありません。\nすべてのタスクが完了しています！"
        case .completed:
            return "このプロジェクトには完了したタスクがありません。"
        case .overdue:
            return "このプロジェクトには期限切れのタスクがありません。"
        case .today:
            return "今日のタスクはありません。"
        case .upcoming:
            return "今後のタスクはありません。"
        }
    }
    
    // プロジェクトのタスクを読み込む
    private func loadProjectTasks() {
        filterTasks()
    }
    
    // タスクをフィルタリング
    private func filterTasks() {
        let projectTasks = taskViewModel.tasks.filter { project.taskIds.contains($0.id) }
        
        switch filter {
        case .all:
            filteredTasks = projectTasks
        case .incomplete:
            filteredTasks = projectTasks.filter { !$0.isCompleted }
        case .completed:
            filteredTasks = projectTasks.filter { $0.isCompleted }
        case .overdue:
            filteredTasks = projectTasks.filter { $0.isOverdue }
        case .today:
            filteredTasks = projectTasks.filter { task in
                if let dueDate = task.dueDate {
                    return Calendar.current.isDateInToday(dueDate)
                }
                return false
            }
        case .upcoming:
            filteredTasks = projectTasks.filter { task in
                if let dueDate = task.dueDate, let daysUntilDue = task.daysUntilDue {
                    return daysUntilDue > 0 && daysUntilDue <= 7
                }
                return false
            }
        }
        
        // ソート：未完了タスクを優先度順、完了タスクを完了日順にする
        filteredTasks.sort { task1, task2 in
            if task1.isCompleted && !task2.isCompleted {
                return false
            } else if !task1.isCompleted && task2.isCompleted {
                return true
            } else if task1.isCompleted && task2.isCompleted {
                // 両方完了済み -> 完了日で降順
                if let date1 = task1.completionDate, let date2 = task2.completionDate {
                    return date1 > date2
                }
                return false
            } else {
                // 両方未完了 -> 優先度と期限で昇順
                if task1.priority.rawValue != task2.priority.rawValue {
                    return task1.priority.rawValue > task2.priority.rawValue
                } else if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                } else if task1.dueDate != nil {
                    return true
                } else {
                    return false
                }
            }
        }
    }
}

// プロジェクト編集ビュー
struct ProjectEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var project: Project
    var onSave: (Project) -> Void
    
    @State private var name: String
    @State private var description: String
    @State private var colorHex: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var showingDueDatePicker: Bool = false
    
    // カラーパレット
    private let colorPalette = [
        "#4A90E2", // 青
        "#50C356", // 緑
        "#E2A64A", // オレンジ
        "#E24A6E", // 赤
        "#9B59B6", // 紫
        "#3498DB", // 水色
        "#1ABC9C", // ティール
        "#F39C12", // 黄色
        "#E74C3C", // 赤
        "#34495E"  // 紺
    ]
    
    init(project: Project, onSave: @escaping (Project) -> Void) {
        self.project = project
        self.onSave = onSave
        
        self._name = State(initialValue: project.name)
        self._description = State(initialValue: project.description ?? "")
        self._colorHex = State(initialValue: project.colorHex)
        self._hasDueDate = State(initialValue: project.dueDate != nil)
        self._dueDate = State(initialValue: project.dueDate ?? Date().adding(days: 14) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    // プロジェクト名入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("プロジェクト名")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("プロジェクト名", text: $name)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // 説明入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("説明（任意）")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: $description)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .frame(minHeight: 120)
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // カラー選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("カラー")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(colorPalette, id: \.self) { hex in
                                Button(action: {
                                    colorHex = hex
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex) ?? .blue)
                                            .frame(width: 40, height: 40)
                                        
                                        if colorHex == hex {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 2)
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                }
                            }
                            
                            // ランダムカラーオプション
                            Button(action: {
                                let colors = colorPalette
                                colorHex = colors.randomElement() ?? "#4A90E2"
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "dice")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding()
                        .background(DesignSystem.Colors.card)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // 期限日設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Toggle("期限日", isOn: $hasDueDate)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        
                        if hasDueDate {
                            HStack {
                                Text(dueDate.formatted())
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingDueDatePicker.toggle()
                                }) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            
                            if showingDueDatePicker {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .labelsHidden()
                                    .padding()
                                    .background(DesignSystem.Colors.card)
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("プロジェクトを編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveProject()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveProject() {
        var updatedProject = project
        updatedProject.name = name
        updatedProject.description = description.isEmpty ? nil : description
        updatedProject.colorHex = colorHex
        updatedProject.dueDate = hasDueDate ? dueDate : nil
        
        onSave(updatedProject)
        presentationMode.wrappedValue.dismiss()
    }
}

// プロジェクトを選択した状態での新規タスク作成ビュー
struct TaskCreationViewWithProject: View {
    var projectId: UUID
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        TaskCreationView()
            .onAppear {
                // ここでプロジェクトを選択状態にするロジックを追加する
                // TaskCreationViewの実装に依存するため、実際の実装方法は調整が必要
            }
    }
}

// プロジェクトタスクフィルター
enum ProjectTaskFilter: CaseIterable {
    case all
    case incomplete
    case completed
    case overdue
    case today
    case upcoming
    
    var title: String {
        switch self {
        case .all: return "すべて"
        case .incomplete: return "未完了"
        case .completed: return "完了"
        case .overdue: return "期限切れ"
        case .today: return "今日"
        case .upcoming: return "今後"
        }
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProjectDetailView(project: Project.samples[0])
                .environmentObject(TaskViewModel())
                .environmentObject(ProjectViewModel())
        }
    }
}
