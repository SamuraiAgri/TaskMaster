import SwiftUI

struct PriorityTasksView: View {
    var tasks: [Task]
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("高優先度タスク")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: TaskListView(initialFilter: .highPriority)) {
                    Text("すべて見る")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(tasks.prefix(3)) { task in
                    PriorityTaskRowView(task: task)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
}

struct PriorityTaskRowView: View {
    @State var task: Task
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var isCompleted: Bool
    
    init(task: Task) {
        self._task = State(initialValue: task)
        self._isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // 優先度アイコン
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.error)
                .frame(width: 24, height: 24)
            
            // タスク情報
            NavigationLink(destination: TaskDetailView(taskId: task.id)) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    // タイトル
                    Text(task.title)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: DesignSystem.Spacing.s) {
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
                        
                        // 期限日
                        if let dueDate = task.dueDate {
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundColor(taskViewModel.dueDateColor(for: task))
                                
                                Text(dueDate.relativeDisplay)
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                    .foregroundColor(taskViewModel.dueDateColor(for: task))
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 完了ボタン
            Button(action: {
                isCompleted.toggle()
                taskViewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// プレビュー
struct PriorityTasksView_Previews: PreviewProvider {
    static var previews: some View {
        PriorityTasksView(tasks: Task.samples.filter { $0.priority == .high })
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
    }
}
