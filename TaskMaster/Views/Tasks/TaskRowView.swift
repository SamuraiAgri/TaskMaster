import SwiftUI

// 優先度インジケーター
struct DetailPriorityIndicator: View {
    var priority: Priority
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(Color.priorityColor(priority))
                .frame(width: 8, height: 8)
            
            Text(priority.title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .accessibilityLabel("\(priority.title)優先度")
    }
}

// プロジェクトインジケーター
struct ProjectIndicatorView: View {
    var project: TMProject
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(project.color)
                .frame(width: 8, height: 8)
            
            Text(project.name)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityLabel("プロジェクト: \(project.name)")
    }
}

// タグインジケーター
struct TagIndicatorView: View {
    var tag: TMTag
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityLabel("タグ: \(tag.name)")
    }
}

// 期限日表示
struct DueDateView: View {
    var dueDate: Date
    var isOverdue: Bool
    var isCompleted: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
            let color = isCompleted ? DesignSystem.Colors.success : (isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
            
            Text(dueDate.relativeDisplay)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                .foregroundColor(color)
            
            // 時間表示（00:00以外の場合）
            let time = dueDate.formatted(with: "HH:mm")
            if time != "00:00" {
                Text(time)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    .foregroundColor(color)
            }
        }
        .accessibilityLabel("期限: \(dueDate.formatted(style: .medium, showTime: true))")
    }
}

// タスク行（コンパクト版）
struct CompactTaskRowView: View {
    var task: TMTask
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            // 優先度マーク
            Circle()
                .fill(Color.priorityColor(task.priority))
                .frame(width: 8, height: 8)
            
            // タイトル
            Text(task.title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                .foregroundColor(task.isCompleted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                .strikethrough(task.isCompleted)
                .lineLimit(1)
            
            Spacer()
            
            // 期限日（あれば）
            if let dueDate = task.dueDate {
                Text(dueDate.formatted(with: "MM/dd"))
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    .foregroundColor(taskViewModel.dueDateColor(for: task))
            }
        }
        .padding(DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// プレビュー
struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // コンパクトタスク行
            CompactTaskRowView(task: TMTask.samples[0])
                .environmentObject(TaskViewModel())
            
            // 詳細タスク行
            DetailPriorityIndicator(priority: .medium)
        }
        .padding()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel())
        .environmentObject(TagViewModel())
        .previewLayout(.sizeThatFits)
    }
}
