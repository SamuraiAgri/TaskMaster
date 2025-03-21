import SwiftUI

struct TodayTasksView: View {
    var tasks: [TMTask]
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("今日のタスク")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: TaskListView(initialFilter: .today)) {
                    Text("すべて見る")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(tasks.prefix(3)) { task in
                    TodayTaskRowView(task: task)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
}

struct TodayTaskRowView: View {
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
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            }
            
            // タスク情報
            NavigationLink(destination: TaskDetailView(taskId: task.id)) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    // タイトル
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
                        
                        // 時間（ある場合）
                        if let dueDate = task.dueDate {
                            let time = dueDate.formatted(with: "HH:mm")
                            if time != "00:00" {
                                Text(time)
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                    .foregroundColor(taskViewModel.dueDateColor(for: task))
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // タグ（最初の1つだけ表示）
            if !task.tagIds.isEmpty, let tagId = task.tagIds.first, let tag = tagViewModel.getTag(by: tagId) {
                TagView(tag: tag, isCompact: true)
            }
        }
        .padding(DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// プレビュー
struct TodayTasksView_Previews: PreviewProvider {
    static var previews: some View {
        TodayTasksView(tasks: TMTask.samples)
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
    }
}
