import SwiftUI

struct ProjectDetailView: View {
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    // プロジェクト
    var project: Project
    @State private var tmProject: TMProject
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingNewTaskSheet = false
    @State private var filter: ProjectTaskFilter = .all
    
    // フィルタリングされたタスク
    @State private var filteredTasks: [TMTask] = []
    
    // 初期化
    init(project: Project) {
        self.project = project
        // CoreData Projectから表示用のTMProjectに変換
        let initialTMProject = TMProject(
            id: project.id ?? UUID(),
            name: project.name ?? "",
            description: project.projectDescription,
            colorHex: project.colorHex ?? "#4A90E2",
            creationDate: project.creationDate ?? Date(),
            dueDate: project.dueDate,
            completionDate: project.completionDate,
            taskIds: project.tasks?.compactMap { ($0 as? Task)?.id ?? UUID() } ?? []
        )
        self._tmProject = State(initialValue: initialTMProject)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.m) {
                // プロジェクトヘッダー
                VStack(spacing: DesignSystem.Spacing.m) {
                    // 進捗バー
                    let progress = projectViewModel.calculateProgress(for: tmProject, tasks: taskViewModel.tasks)
                    
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
                        
                        ProgressBarView(value: progress, color: tmProject.color, height: 10)
                    }
                    
                    // プロジェクト統計
                    HStack {
                        let projectTasks = taskViewModel.tasks.filter { tmTask in
                            if let projectId = project.id {
                                return tmTask.projectId == projectId
                            }
                            return false
                        }
                        let totalTasks = projectTasks.count
                        let completedTasks = projectTasks.filter { $0.isCompleted }.count
                        
                        // 完了タスク
                        StatCardSimple(
                            title: "完了",
                            value: "\(completedTasks)",
                            iconName: "checkmark.circle",
                            color: DesignSystem.Colors.success
                        )
                        
                        // 未完了タスク
                        StatCardSimple(
                            title: "未完了",
                            value: "\(totalTasks - completedTasks)",
                            iconName: "circle",
                            color: DesignSystem.Colors.warning
                        )
                        
                        // 合計タスク
                        StatCardSimple(
                            title: "合計",
                            value: "\(totalTasks)",
                            iconName: "list.bullet",
                            color: tmProject.color
                        )
                    }
                    
                    // 完了ボタン
                    if tmProject.isCompleted {
                        Button(action: {
                            var updatedProject = tmProject
                            updatedProject.completionDate = nil
                            projectViewModel.updateProject(updatedProject)
                            tmProject = updatedProject
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
                            var updatedProject = tmProject
                            updatedProject.completionDate = Date()
                            projectViewModel.updateProject(updatedProject)
                            tmProject = updatedProject
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
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                // プロジェクト詳細
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // タイトルと色
                    HStack {
                        Text(tmProject.name)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.title3, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Circle()
                            .fill(tmProject.color)
                            .frame(width: 16, height: 16)
                    }
                    
                    // 説明
                    if let description = tmProject.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("説明")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(description)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                    
                    // 日付情報
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        // 作成日
                        HStack {
                            Text("作成日:")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(tmProject.creationDate.formatted())
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        // 期限日
                        if let dueDate = tmProject.dueDate {
                            HStack {
                                Text("期限日:")
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text(dueDate.formatted())
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                    .foregroundColor(tmProject.isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                            }
                        }
                        
                        // 完了日
                        if let completionDate = tmProject.completionDate {
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
                }
                .padding()
                .background(DesignSystem.Colors.card)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                // タスクフィルター
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    Text("タスク一覧")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            ForEach(ProjectTaskFilter.allCases, id: \.self) { filterOption in
                                Button(action: {
                                    filter = filterOption
                                    filterTasks()
                                }) {
                                    Text(filterOption.title)
                                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                        .foregroundColor(filter == filterOption ? .white : DesignSystem.Colors.textPrimary)
                                        .padding(.horizontal, DesignSystem.Spacing.s)
                                        .padding(.vertical, DesignSystem.Spacing.xs)
                                        .background(filter == filterOption ? tmProject.color : DesignSystem.Colors.card)
                                        .cornerRadius(DesignSystem.CornerRadius.small)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(DesignSystem.Colors.card)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                // タスクリスト
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
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                } else {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        ForEach(filteredTasks) { tmTask in
                            NavigationLink(destination: TaskDetailView(taskId: tmTask.id)) {
                                SimpleTaskRowView(task: tmTask)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
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
                }
            }
            .padding()
        }
        .navigationTitle(project.name ?? "プロジェクト詳細")
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
            SimpleProjectEditView(project: tmProject) { updatedProject in
                // TMProjectを更新
                tmProject = updatedProject
                // CoreDataのプロジェクトも更新
                projectViewModel.updateProject(updatedProject)
            }
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            // プロジェクトを選択した状態で新規タスク作成画面を表示
            if let id = project.id {
                TaskCreationViewWithProject(projectId: id)
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("プロジェクトの削除"),
                message: Text("このプロジェクトを削除しますか？関連するタスクは削除されませんが、プロジェクトとの関連付けは解除されます。"),
                primaryButton: .destructive(Text("削除")) {
                    if let id = project.id {
                        projectViewModel.deleteProject(id: id)
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .onAppear {
            loadProjectTasks()
        }
        .onChange(of: filter) { _, _ in
            filterTasks()
        }
        .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
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
        if let projectId = project.id {
            let projectTasks = taskViewModel.tasks.filter { $0.projectId == projectId }
            
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
}

// シンプルなプロジェクト編集ビュー
struct SimpleProjectEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var project: TMProject
    var onSave: (TMProject) -> Void
    
    // 状態変数
    @State private var name: String
    @State private var description: String
    @State private var colorHex: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
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
    
    init(project: TMProject, onSave: @escaping (TMProject) -> Void) {
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
            Form {
                Section(header: Text("基本情報")) {
                    TextField("プロジェクト名", text: $name)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("カラー")) {
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
                                        .frame(width: 32, height: 32)
                                    
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("期限日")) {
                    Toggle("期限を設定", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("期限日", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("プロジェクト編集")
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
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    
    // タスクプロパティ
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: Priority = .medium
    @State private var status: TaskStatus = .notStarted
    @State private var dueDate: Date = Date().adding(days: 1) ?? Date()
    @State private var hasDueDate: Bool = false
    @State private var selectedTagIds: [UUID] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    // タイトル入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("タイトル")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("タスクのタイトルを入力", text: $title)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // 説明入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("説明（任意）")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // 優先度選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("優先度")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack {
                            ForEach(Priority.allCases) { priorityOption in
                                Button(action: {
                                    priority = priorityOption
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(priority == priorityOption ? Color.priorityColor(priorityOption) : Color.priorityColor(priorityOption).opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: priorityIcon(for: priorityOption))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(priorityOption.title)
                                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                            .foregroundColor(priority == priorityOption ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    
                    // 期限日設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Toggle("期限日", isOn: $hasDueDate)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        
                        if hasDueDate {
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding(.vertical, DesignSystem.Spacing.xs)
                        }
                    }
                    
                    // タグ選択
                    if !tagViewModel.tags.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("タグ（任意）")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TagSelectorView(tags: tagViewModel.tags, selectedTagIds: $selectedTagIds)
                        }
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("新規タスク")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    // 優先度に応じたアイコンを取得
    private func priorityIcon(for priority: Priority) -> String {
        switch priority {
        case .low:
            return "arrow.down"
        case .medium:
            return "minus"
        case .high:
            return "exclamationmark"
        }
    }
    
    // タスクを保存
    private func saveTask() {
        if title.isEmpty { return }
        
        var task = TMTask(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            status: status,
            projectId: projectId,
            tagIds: selectedTagIds
        )
        
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        taskViewModel.addTask(task)
        presentationMode.wrappedValue.dismiss()
    }
}

// シンプルな統計カード
struct StatCardSimple: View {
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

// プレビュー
struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // CoreDataコンテキストからプロジェクトを取得する必要がある
            let context = PersistenceController.preview.container.viewContext
            let project = Project(context: context)
            project.id = UUID()
            project.name = "サンプルプロジェクト"
            project.projectDescription = "これはサンプルプロジェクトの説明です"
            project.colorHex = "#4A90E2"
            
            return ProjectDetailView(project: project)
                .environmentObject(TaskViewModel())
                .environmentObject(ProjectViewModel())
                .environmentObject(TagViewModel())
        }
    }
}
