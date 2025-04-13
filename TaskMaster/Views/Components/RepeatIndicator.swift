import SwiftUI

struct RepeatIndicator: View {
    var repeatType: RepeatType
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: isCompact ? 10 : 12))
                .foregroundColor(DesignSystem.Colors.primary)
            
            if !isCompact {
                Text(repeatType.rawValue)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
        .padding(.vertical, isCompact ? 2 : DesignSystem.Spacing.xxs)
        .background(DesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// カスタム繰り返し表示用
struct CustomRepeatIndicator: View {
    var repeatValue: Int
    var isCompact: Bool = false
    
    private var displayText: String {
        if repeatValue % 30 == 0 {
            let months = repeatValue / 30
            return months == 1 ? "毎月" : "\(months)ヶ月ごと"
        } else if repeatValue % 7 == 0 {
            let weeks = repeatValue / 7
            return weeks == 1 ? "毎週" : "\(weeks)週ごと"
        } else {
            return repeatValue == 1 ? "毎日" : "\(repeatValue)日ごと"
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: isCompact ? 10 : 12))
                .foregroundColor(DesignSystem.Colors.primary)
            
            if !isCompact {
                Text(displayText)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
        .padding(.vertical, isCompact ? 2 : DesignSystem.Spacing.xxs)
        .background(DesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// プレビュー
struct RepeatIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 繰り返しタイプ
            RepeatIndicator(repeatType: .daily)
            RepeatIndicator(repeatType: .weekly)
            RepeatIndicator(repeatType: .custom, isCompact: true)
            
            // カスタム繰り返し
            CustomRepeatIndicator(repeatValue: 1)
            CustomRepeatIndicator(repeatValue: 3)
            CustomRepeatIndicator(repeatValue: 7)
            CustomRepeatIndicator(repeatValue: 14)
            CustomRepeatIndicator(repeatValue: 30)
            CustomRepeatIndicator(repeatValue: 90)
            CustomRepeatIndicator(repeatValue: 14, isCompact: true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
