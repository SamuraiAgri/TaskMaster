import SwiftUI

struct SimpleTaskEditView: View {
    @Environment(\.presentationMode) var presentationMode
    var task: TMTask
    var onSave: (TMTask) -> Void
    
    // 状態変数
    @State private var title: String
    @State private var description: String
    @State private var priority: Priority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    // 繰り返し設定
    @State private var isRepeating: Bool
    @State private var repeatType: RepeatType
    @State private var repeatCustomValue: Int?
    @State private var showingRepeatSettings = false
    
    init(task: TMTask, onSave: @escaping (TMTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        // 状態変数の初期化
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description ?? "")
        self._priority = State(initialValue: task.priority)
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        
        // 繰り返し設定の初期化
        self._isRepeating = State(initialValue: task.isRepeating)
        self._repeatType = State(initialValue: task.repeatType)
        self._repeatCustomValue = State(initialValue: task.repeatCustomValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("優先度")) {
                    Picker("優先度", selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            HStack {
                                Circle()
                                    .fill(Color.priorityColor(priority))
                                    .frame(width: 10, height: 10)
                                
                                Text(priority.title)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("期限日")) {
                    Toggle("期限を設定", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("期限日", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("繰り返し")) {
                    Button(action: {
                        showingRepeatSettings = true
                    }) {
                        HStack {
                            Text("繰り返し設定")
                            
                            Spacer()
                            
                            if isRepeating {
                                if repeatType == .custom, let customValue = repeatCustomValue {
                                    CustomRepeatIndicator(repeatValue: customValue, isCompact: true)
                                } else {
                                    RepeatIndicator(repeatType: repeatType, isCompact: true)
                                }
                            } else {
                                Text("なし")
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .sheet(isPresented: $showingRepeatSettings) {
                        RepeatSettingsView(
                            isRepeating: $isRepeating,
                            repeatType: $repeatType,
                            repeatCustomValue: $repeatCustomValue
                        )
                    }
                    
                    if isRepeating {
                        Text(getRepeatDescription())
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("タスクの編集")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    var updatedTask = task
                    updatedTask.title = title
                    updatedTask.description = description.isEmpty ? nil : description
                    updatedTask.priority = priority
                    updatedTask.dueDate = hasDueDate ? dueDate : nil
                    
                    // 繰り返し設定
                    updatedTask.isRepeating = isRepeating
                    updatedTask.repeatType = isRepeating ? repeatType : .none
                    updatedTask.repeatCustomValue = isRepeating && repeatType == .custom ? repeatCustomValue : nil
                    
                    onSave(updatedTask)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    // 繰り返しの説明文を取得
    private func getRepeatDescription() -> String {
        if !isRepeating {
            return ""
        }
        
        switch repeatType {
        case .none:
            return ""
        case .daily:
            return "毎日繰り返します。完了したら翌日に新しいタスクが作成されます。"
        case .weekdays:
            return "平日（月曜日から金曜日）のみ繰り返します。"
        case .weekly:
            return "毎週同じ曜日に繰り返します。"
        case .monthly:
            return "毎月同じ日に繰り返します。"
        case .yearly:
            return "毎年同じ日に繰り返します。"
        case .custom:
            if let value = repeatCustomValue {
                if value % 30 == 0 {
                    let months = value / 30
                    return months == 1 ? "毎月繰り返します。" : "\(months)ヶ月ごとに繰り返します。"
                } else if value % 7 == 0 {
                    let weeks = value / 7
                    return weeks == 1 ? "毎週繰り返します。" : "\(weeks)週間ごとに繰り返します。"
                } else {
                    return value == 1 ? "毎日繰り返します。" : "\(value)日ごとに繰り返します。"
                }
            }
            return "カスタム繰り返し設定です。"
        }
    }
}

struct SimpleTaskEditView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleTaskEditView(
            task: TMTask(
                title: "サンプルタスク",
                priority: .medium
            ),
            onSave: { _ in }
        )
    }
}
