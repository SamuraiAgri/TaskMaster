import SwiftUI

// 注意: TaskListView.swiftにも同様の実装がありますが、
// コンポーネントとして独立させる場合の実装例です

struct TaskRowView: View {
    @State var task: Task
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    @State private var isCompleted: Bool
    
    init(task: Task) {
        self._task = State(initialValue: task)
        self._isCompleted = State(initialValue: task.isCompleted)
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
            .accessibilityLabel(isCompleted ? "タスク完了" : "タスク未完了")
            
            // タスク情報
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                // タスクタイトル
                Text(task.title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isCompleted ? .regular : .medium))
                    .foregroundColor(isCompleted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                    .strikethrough(isCompleted)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.s) {
                    // 優先度
                    PriorityIndicatorView(priority: task.priority)
                    
                    // プロジェクト
                    if let projectId = task.projectId, let project = projectViewModel.getProject(by: projectId) {
                        ProjectIndicatorView(project: project)
                    }
                    
                    // タグ（一つだけ表示）
                    if !task.tagIds.isEmpty, let tagId = task.tagIds.first, let tag = tagViewModel.getTag(by: tagId) {
                        TagIndicatorView(tag: tag)
                    }
                }
            }
            
            Spacer()
            
            // 期限日
            if let dueDate = task.dueDate {
                DueDateView(dueDate: dueDate, isOverdue: task.isOverdue, isCompleted: task.isCompleted)
            }
            
            // 繰り返しタスクマーク
            if task.isRepeating {
                Image(systemName: "repeat")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.leading, -DesignSystem.Spacing.s)
            }
        }
        .padding(DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .contentShape(Rectangle()) // タップ領域をセル全体に拡張
    }
}

// 優先度インジケーター
struct PriorityIndicatorView: View {
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
    var project: Project
    
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
    var tag: Tag
    
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

// スワイプアクション付きタスク行
struct SwipeableTaskRowView: View {
    var task: Task
    var onDelete: () -> Void
    var onEdit: () -> Void
    var onComplete: () -> Void
    
    @State private var offset: CGFloat = 0
    private let swipeThreshold: CGFloat = 60
    
    var body: some View {
        ZStack {
            // 背景（アクションボタン）
            HStack(spacing: 0) {
                Spacer()
                
                // 完了ボタン
                Button(action: onComplete) {
                    VStack {
                        Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        Text(task.isCompleted ? "元に戻す" : "完了")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    }
                    .foregroundColor(.white)
                    .frame(width: swipeThreshold, height: double.infinity)
                    .background(task.isCompleted ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                }
                
                // 編集ボタン
                Button(action: onEdit) {
                    VStack {
                        Image(systemName: "pencil")
                        Text("編集")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    }
                    .foregroundColor(.white)
                    .frame(width: swipeThreshold, height: .infinity)
                    .background(DesignSystem.Colors.primary)
                }
                
                // 削除ボタン
                Button(action: onDelete) {
                    VStack {
                        Image(systemName: "trash")
                        Text("削除")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    }
                    .foregroundColor(.white)
                    .frame(width: swipeThreshold, height: .infinity)
                    .background(DesignSystem.Colors.error)
                }
            }
            
            // タスク行
            TaskRowView(task: task)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            // 左スワイプのみ許可
                            if gesture.translation.width < 0 {
                                offset = gesture.translation.width
                            }
                        }
                        .onEnded { gesture in
                            if -gesture.translation.width > swipeThreshold * 3 {
                                // 大きく左スワイプ -> 削除
                                offset = -swipeThreshold * 3
                                onDelete()
                            } else if -gesture.translation.width > swipeThreshold * 2 {
                                // 中くらい左スワイプ -> 編集
                                offset = -swipeThreshold * 2
                                onEdit()
                            } else if -gesture.translation.width > swipeThreshold {
                                // 小さく左スワイプ -> 完了
                                offset = -swipeThreshold
                                onComplete()
                            } else {
                                // スワイプが閾値未満 -> 元の位置に戻す
                                offset = 0
                            }
                        }
                )
                .animation(.spring(), value: offset)
        }
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .clipped() // はみ出た部分を切り取る
    }
}

// タスク行（コンパクト版）
struct CompactTaskRowView: View {
    var task: Task
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
            // 通常のタスク行
            TaskRowView(task: Task.samples[0])
            
            // 完了済みタスク行
            TaskRowView(task: Task.samples[3])
            
            // コンパクトタスク行
            CompactTaskRowView(task: Task.samples[0])
            
            // スワイプアクション付きタスク行
            SwipeableTaskRowView(
                task: Task.samples[0],
                onDelete: {},
                onEdit: {},
                onComplete: {}
            )
        }
        .padding()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel())
        .environmentObject(TagViewModel())
        .previewLayout(.sizeThatFits)
    }
}
