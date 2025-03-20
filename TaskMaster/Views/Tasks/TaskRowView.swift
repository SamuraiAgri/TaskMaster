import SwiftUI

// 注意: TaskListView.swiftにも同様の実装がありますが、
// コンポーネントとして独立させる場合の実装例です

struct TaskDetailRowView: View {  // TaskRowViewからTaskDetailRowViewに変更
    @State var task: Task
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    @State private var isCompleted: Bool
    
    init(task: Task) {
        self._task = State(initialValue: task)
        self._isCompleted = State(initialValue: task.status == "完了")
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // 完了チェックボックス
            Button(action: {
                isCompleted.toggle()
                // TaskをTMTask形式に変換してからトグル
                let tmTask = TMTask(
                    id: task.id ?? UUID(),
                    title: task.title ?? "",
                    description: task.taskDescription,
                    creationDate: task.creationDate ?? Date(),
                    dueDate: task.dueDate,
                    completionDate: task.completionDate,
                    priority: Priority(rawValue: Int(task.priority)) ?? .medium,
                    status: TaskStatus(rawValue: task.status ?? "") ?? .notStarted,
                    projectId: task.project?.id,
                    tagIds: Array(task.tags?.compactMap { ($0 as? Tag)?.id } ?? [])
                )
                taskViewModel.toggleTaskCompletion(tmTask)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            }
            .accessibilityLabel(isCompleted ? "タスク完了" : "タスク未完了")
            
            // タスク情報
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                // タスクタイトル
                Text(task.title ?? "")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isCompleted ? .regular : .medium))
                    .foregroundColor(isCompleted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                    .strikethrough(isCompleted)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.s) {
                    // 優先度
                    DetailPriorityIndicator(priority: Priority(rawValue: Int(task.priority)) ?? .medium)
                    
                    // プロジェクト
                    if let project = task.project {
                        ProjectIndicatorView(project: project)
                    }
                    
                    // タグ（一つだけ表示）
                    if let tag = task.tags?.firstObject as? Tag {
                        TagIndicatorView(tag: tag)
                    }
                }
            }
            
            Spacer()
            
            // 期限日
            if let dueDate = task.dueDate {
                let isOverdue = dueDate < Date() && task.status != "完了"
                DueDateView(dueDate: dueDate, isOverdue: isOverdue, isCompleted: task.status == "完了")
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
struct DetailPriorityIndicator: View {  // PriorityIndicatorViewからDetailPriorityIndicatorに変更
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
                .fill(Color(hex: project.colorHex ?? "#4A90E2") ?? .blue)
                .frame(width: 8, height: 8)
            
            Text(project.name ?? "")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityLabel("プロジェクト: \(project.name ?? "")")
    }
}

// タグインジケーター
struct TagIndicatorView: View {
    var tag: Tag
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(Color(hex: tag.colorHex ?? "#AAAAAA") ?? .gray)
                .frame(width: 8, height: 8)
            
            Text(tag.name ?? "")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityLabel("タグ: \(tag.name ?? "")")
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
                        Image(systemName: task.status == "完了" ? "arrow.uturn.backward" : "checkmark")
                        Text(task.status == "完了" ? "元に戻す" : "完了")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    }
                    .foregroundColor(.white)
                    .frame(width: swipeThreshold, height: .infinity)
                    .background(task.status == "完了" ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
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
                .fill(Color.priorityColor(Priority(rawValue: Int(task.priority)) ?? .medium))
                .frame(width: 8, height: 8)
            
            // タイトル
            Text(task.title ?? "")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                .foregroundColor(task.status == "完了" ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                .strikethrough(task.status == "完了")
                .lineLimit(1)
            
            Spacer()
            
            // 期限日（あれば）
            if let dueDate = task.dueDate {
                // TMTaskの変換を用意
                let tmTask = TMTask(
                    id: task.id ?? UUID(),
                    title: task.title ?? "",
                    description: task.taskDescription,
                    creationDate: task.creationDate ?? Date(),
                    dueDate: task.dueDate,
                    completionDate: task.completionDate,
                    priority: Priority(rawValue: Int(task.priority)) ?? .medium,
                    status: TaskStatus(rawValue: task.status ?? "") ?? .notStarted
                )
                
                Text(dueDate.formatted(with: "MM/dd"))
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    .foregroundColor(taskViewModel.dueDateColor(for: tmTask))
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
            let task = Task()
            task.title = "サンプルタスク"
            task.priority = 2
            CompactTaskRowView(task: task)
            
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
