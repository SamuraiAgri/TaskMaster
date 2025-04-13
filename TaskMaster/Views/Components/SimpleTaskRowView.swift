import SwiftUI

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
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(task.title)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isCompleted ? .regular : .medium))
                        .foregroundColor(isCompleted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .strikethrough(isCompleted)
                        .lineLimit(1)
                    
                    // 繰り返しアイコン（繰り返しタスクの場合）
                    if task.isRepeating {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
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

// プレビュー
struct SimpleTaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleTaskRowView(task: TMTask(title: "サンプルタスク", priority: .medium))
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
