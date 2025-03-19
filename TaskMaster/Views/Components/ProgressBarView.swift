import SwiftUI

struct ProgressBarView: View {
    var value: Double // 0.0〜1.0の値
    var color: Color = DesignSystem.Colors.primary
    var showPercentage: Bool = false
    var height: CGFloat = 8
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: height)
                    
                    // 進捗
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(max(value, 0.0), 1.0)), height: height)
                }
            }
            .frame(height: height)
            
            // パーセンテージの表示（オプション）
            if showPercentage {
                Text("\(Int(value * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// アニメーション付きのプログレスバー
struct AnimatedProgressBarView: View {
    @State private var progress: CGFloat = 0
    var value: Double // 0.0〜1.0の値
    var color: Color = DesignSystem.Colors.primary
    var showPercentage: Bool = false
    var height: CGFloat = 8
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: height)
                    
                    // 進捗
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: height)
                }
            }
            .frame(height: height)
            
            // パーセンテージの表示（オプション）
            if showPercentage {
                Text("\(Int(value * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                progress = CGFloat(min(max(value, 0.0), 1.0))
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                progress = CGFloat(min(max(newValue, 0.0), 1.0))
            }
        }
    }
}

// カスタムフォームのプログレスバー
struct SteppedProgressBarView: View {
    var currentStep: Int
    var totalSteps: Int
    var color: Color = DesignSystem.Colors.primary
    var height: CGFloat = 4
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step < currentStep ? color : color.opacity(0.2))
                    .frame(height: height)
                    .cornerRadius(step == 0 ? height/2 : 0, corners: [.topLeft, .bottomLeft])
                    .cornerRadius(step == totalSteps - 1 ? height/2 : 0, corners: [.topRight, .bottomRight])
            }
        }
    }
}

// 角丸の設定
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// カスタム角丸形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// プレビュー
struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 通常のプログレスバー
            ProgressBarView(value: 0.45)
                .padding()
            
            // パーセンテージ表示付き
            ProgressBarView(value: 0.75, color: .blue, showPercentage: true)
                .padding()
            
            // アニメーション付き
            AnimatedProgressBarView(value: 0.65, color: .green, showPercentage: true)
                .padding()
            
            // ステップ表示
            SteppedProgressBarView(currentStep: 2, totalSteps: 5, color: .orange)
                .padding()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
