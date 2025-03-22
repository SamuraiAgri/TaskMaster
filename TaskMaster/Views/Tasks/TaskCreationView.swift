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
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []
    @State private var hasDueDate: Bool = false
    
    // バリデーション
    @State private var titleError: String? = nil
    
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
                            .onChange(of: title) { oldValue, newValue in
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
                        }
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
                    
                    // プロジェクト選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("プロジェクト（任意）")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.s) {
                                // 「なし」オプション
                                Button(action: {
                                    selectedProjectId = nil
                                }) {
                                    Text("なし")
                                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                        .padding(.horizontal, DesignSystem.Spacing.s)
                                        .padding(.vertical, DesignSystem.Spacing.xs)
                                        .foregroundColor(selectedProjectId == nil ? .white : DesignSystem.Colors.textSecondary)
                                        .background(selectedProjectId == nil ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textSecondary.opacity(0.2))
                                        .cornerRadius(DesignSystem.CornerRadius.small)
                                }
                                
                                ForEach(projectViewModel.projects) { project in
                                    Button(action: {
                                        selectedProjectId = project.id
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(project.color)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(project.name)
                                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.s)
                                        .padding(.vertical, DesignSystem.Spacing.xs)
                                        .foregroundColor(selectedProjectId == project.id ? .white : project.color)
                                        .background(selectedProjectId == project.id ? project.color : project.color.opacity(0.2))
                                        .cornerRadius(DesignSystem.CornerRadius.small)
                                    }
                                }
                            }
                        }
                    }
                    
                    // タグ選択（省略可能）
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
            tagIds: selectedTagIds
        )
        
        // 期限日の設定
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        // タスクの保存
        taskViewModel.addTask(task)
        
        // フォームを閉じる
        presentationMode.wrappedValue.dismiss()
    }
}

struct TaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        TaskCreationView()
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
    }
}
