import SwiftUI

struct PriorityBadgeView: View {
    var priority: Priority
    var showText: Bool = true
    var compactMode: Bool = false
    
    var body: some View {
        HStack(spacing: compactMode ? DesignSystem.Spacing.xxs : DesignSystem.Spacing.xs) {
            // 優先度を示す丸い色の付いたマーク
            Circle()
                .fill(Color.priorityColor(priority))
                .frame(width: compactMode ? 6 : 8, height: compactMode ? 6 : 8)
            
            // 優先度のテキスト（オプション）
            if showText {
                Text(priority.title)
                    .font(DesignSystem.Typography.font(
                        size: compactMode ? DesignSystem.Typography.caption2 : DesignSystem.Typography.caption1
                    ))
                    .foregroundColor(Color.priorityColor(priority))
            }
        }
        .padding(.horizontal, compactMode ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
        .padding(.vertical, compactMode ? 2 : DesignSystem.Spacing.xxs)
        .background(Color.priorityColor(priority).opacity(0.2))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(Color.priorityColor(priority).opacity(0.3), lineWidth: 0.5)
        )
    }
}

// より大きな優先度表示ボタン
struct PriorityButtonView: View {
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
        .accessibilityLabel("\(priority.title)優先度")
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

// 一覧用の小さな優先度インジケーター
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

// フィルター用の優先度選択ボタン
struct PriorityFilterButtonView: View {
    var priority: Priority
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(priority.title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                .padding(.horizontal, DesignSystem.Spacing.s)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .foregroundColor(isSelected ? .white : Color.priorityColor(priority))
                .background(isSelected ? Color.priorityColor(priority) : Color.priorityColor(priority).opacity(0.2))
                .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .accessibilityLabel("\(priority.title)優先度")
    }
}

// プレビュー
struct PriorityBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 通常のバッジ
            HStack(spacing: 20) {
                PriorityBadgeView(priority: .low)
                PriorityBadgeView(priority: .medium)
                PriorityBadgeView(priority: .high)
            }
            
            // コンパクトモード
            HStack(spacing: 20) {
                PriorityBadgeView(priority: .low, compactMode: true)
                PriorityBadgeView(priority: .medium, compactMode: true)
                PriorityBadgeView(priority: .high, compactMode: true)
            }
            
            // テキストなし
            HStack(spacing: 20) {
                PriorityBadgeView(priority: .low, showText: false)
                PriorityBadgeView(priority: .medium, showText: false)
                PriorityBadgeView(priority: .high, showText: false)
            }
            
            // ボタンビュー
            HStack(spacing: 20) {
                PriorityButtonView(priority: .low, isSelected: false, action: {})
                PriorityButtonView(priority: .medium, isSelected: true, action: {})
                PriorityButtonView(priority: .high, isSelected: false, action: {})
            }
            
            // インジケーター
            HStack(spacing: 20) {
                PriorityIndicatorView(priority: .low)
                PriorityIndicatorView(priority: .medium)
                PriorityIndicatorView(priority: .high)
            }
            
            // フィルターボタン
            HStack(spacing: 20) {
                PriorityFilterButtonView(priority: .low, isSelected: false, action: {})
                PriorityFilterButtonView(priority: .medium, isSelected: true, action: {})
                PriorityFilterButtonView(priority: .high, isSelected: false, action: {})
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
