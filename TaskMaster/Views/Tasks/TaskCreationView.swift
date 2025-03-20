import SwiftUI

struct TaskCreationView: View {
    // 環境変数
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
    @State private var reminderDate: Date = Date()
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []
    @State private var isRepeating: Bool = false
    @State private var repeatType: RepeatType = .none
    
    // UI制御プロパティ
    @State private var showingDueDatePicker: Bool = false
    @State private var showingReminderPicker: Bool = false
    @State private var hasDueDate: Bool = true
    @State private var hasReminder: Bool = false
    @State private var activeSection: FormSection? = .basic
    
    // バリデーション
    @State private var titleError: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // 基本情報セクション
                    basicInfoSection
                    
                    Divider()
                    
                    // 詳細情報セクション
                    detailInfoSection
                    
                    Divider()
                    
                    // スケジュールセクション
                    scheduleInfoSection
                    
                    Divider()
                    
                    // 分類セクション
                    categorySection
                }
                .padding()
            }
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("新規タスク")
            .navigationBarTitleDisplayMode(.inline)
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
    
    // 基本情報セクション
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            sectionHeader(title: "基本情報", section: .basic)
            
            if activeSection == .basic {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // タイトル入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("タイトル")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("タスクのタイトルを入力", text: $title)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .onChange(of: title) { newValue in
                                if newValue.isEmpty {
                                    titleError = "タイトルは必須です"
                                } else {
                                    titleError = nil
                                }
                            }
                        
                        if let error = titleError {
                            Text(error)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                .foregroundColor(DesignSystem.Colors.error)
                                .padding(.leading, DesignSystem.Spacing.xs)
                        }
                    }
                    
                    // 説明入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("説明")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // 優先度選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("優先度")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack {
                            ForEach(Priority.allCases) { priority in
                                PriorityButton(
                                    priority: priority,
                                    isSelected: self.priority == priority,
                                    action: {
                                        self.priority = priority
                                    }
                                )
                            }
                        }
                    }
                    
                    // ステータス選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("ステータス")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        statusPicker
                    }
                }
            }
        }
    }
    
    // 詳細情報セクション
    private var detailInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            sectionHeader(title: "詳細情報", section: .details)
            
            if activeSection == .details {
                // ここに詳細情報のコンテンツを実装
                Text("詳細情報はまだ実装されていません")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding()
            }
        }
    }
    
    // スケジュールセクション
    private var scheduleInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            sectionHeader(title: "スケジュール", section: .schedule)
            
            if activeSection == .schedule {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // 期限日設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Toggle("期限日", isOn: $hasDueDate)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
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
                    
                    // 繰り返し設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Toggle("繰り返し", isOn: $isRepeating)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        
                        if isRepeating {
                            Text("繰り返しタイプ")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            repeatTypePicker
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    
                    // リマインダー設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Toggle("リマインダー", isOn: $hasReminder)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        
                        if hasReminder {
                            HStack {
                                Text(reminderDate.formatted(style: .medium, showTime: true))
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingReminderPicker.toggle()
                                }) {
                                    Image(systemName: "bell")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                            
                            if showingReminderPicker {
                                DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .labelsHidden()
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
        }
    }
    
    // 分類セクション
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            sectionHeader(title: "分類", section: .category)
            
            if activeSection == .category {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    // プロジェクト選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("プロジェクト")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        projectPicker
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    
                    // タグ選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("タグ")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        tagSelectorView
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
        }
    }
    
    // セクションヘッダー
    private func sectionHeader(title: String, section: FormSection) -> some View {
        Button(action: {
            if activeSection == section {
                activeSection = nil
            } else {
                activeSection = section
            }
        }) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: activeSection == section ? "chevron.up" : "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // ステータスピッカー
    private var statusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.m) {
                ForEach(TaskStatus.allCases) { status in
                    Button(action: {
                        self.status = status
                    }) {
                        Text(status.rawValue)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .padding(.horizontal, DesignSystem.Spacing.s)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .foregroundColor(self.status == status ? .white : Color.statusColor(status))
                            .background(self.status == status ? Color.statusColor(status) : Color.statusColor(status).opacity(0.2))
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }
    
    // 繰り返しタイプピッカー
    private var repeatTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.m) {
                ForEach(RepeatType.allCases) { type in
                    Button(action: {
                        self.repeatType = type
                    }) {
                        Text(type.rawValue)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .padding(.horizontal, DesignSystem.Spacing.s)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .foregroundColor(self.repeatType == type ? .white : DesignSystem.Colors.primary)
                            .background(self.repeatType == type ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.2))
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }
    
    // プロジェクトピッカー
    private var projectPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.m) {
                // 「なし」オプション
                Button(action: {
                    self.selectedProjectId = nil
                }) {
                    Text("なし")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .padding(.horizontal, DesignSystem.Spacing.s)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .foregroundColor(selectedProjectId == nil ? .white : DesignSystem.Colors.textSecondary)
                        .background(selectedProjectId == nil ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textSecondary.opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
                
                // プロジェクト一覧
                ForEach(projectViewModel.projects) { project in
                    Button(action: {
                        self.selectedProjectId = project.id
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Circle()
                                .fill(project.color)
                                .frame(width: 8, height: 8)
                            
                            Text(project.name)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.s)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .foregroundColor(selectedProjectId == project.id ? .white : project.color)
                        .background(selectedProjectId == project.id ? project.color : project.color.opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }
    
    // タグセレクター
    private var tagSelectorView: some View {
        let tags = tagViewModel.tags
        
        return TagSelectorView(
            tags: tags.map { tag -> Tag in
                let coreDataTag = Tag(context: dataService.viewContext)
                coreDataTag.id = tag.id
                coreDataTag.name = tag.name
                coreDataTag.colorHex = tag.colorHex
                return coreDataTag
            },
            selectedTagIds: $selectedTagIds
        )
    }
    
    // タスクの保存
    private func saveTask() {
        // バリデーション
        if title.isEmpty {
            titleError = "タイトルは必須です"
            return
        }
        
        // タスクの作成
        var task = TMTask(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            status: status,
            projectId: selectedProjectId,
            tagIds: selectedTagIds,
            isRepeating: isRepeating,
            repeatType: isRepeating ? repeatType : .none
        )
        
        // 期限日の設定
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        // リマインダーの設定
        if hasReminder {
            task.reminderDate = reminderDate
        }
        
        // タスクの保存
        taskViewModel.addTask(task)
        
        // フォームを閉じる
        presentationMode.wrappedValue.dismiss()
    }
    
    // データサービスの取得
    private var dataService: DataServiceProtocol {
        return DataService.shared
    }
}

// フォームセクション
enum FormSection {
    case basic
    case details
    case schedule
    case category
}

// 優先度ボタン
struct PriorityButton: View {
    var priority: Priority
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Circle()
                    .fill(isSelected ? Color.priorityColor(priority) : Color.priorityColor(priority).opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: priorityIcon(for: priority))
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                
                Text(priority.title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
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
}

// プレビュー
struct TaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        TaskCreationView()
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
    }
}
