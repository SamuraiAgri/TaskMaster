import SwiftUI

// MARK: - 円グラフ表示コンポーネント
struct PieChartView: View {
    var value: Double
    var total: Double
    var color: Color
    
    private var percentage: Double {
        total == 0 ? 0 : min(value / total, 1.0)
    }
    
    var body: some View {
        ZStack {
            // 背景円
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 30)
            
            // 進捗円
            Circle()
                .trim(from: 0, to: CGFloat(percentage))
                .stroke(color, lineWidth: 30)
                .rotationEffect(Angle(degrees: -90))
            
            // パーセンテージ表示
            VStack {
                Text("\(Int(percentage * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.largeTitle, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("達成率")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - 棒グラフアイテム
struct BarChartItem: View {
    var value: Int
    var total: Int
    var title: String
    var color: Color
    
    private var percentage: Double {
        total == 0 ? 0 : min(Double(value) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            // 値
            Text("\(value)")
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // バー
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(color)
                .frame(width: 40, height: max(CGFloat(percentage) * 100, 5))
            
            // タイトル
            Text(title)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 水平方向の棒グラフ
struct HorizontalBarChartView: View {
    var items: [(title: String, value: Int, color: Color)]
    var maxValue: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                HStack(spacing: DesignSystem.Spacing.m) {
                    // タイトル
                    Text(item.title)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    // バー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            Rectangle()
                                .fill(item.color.opacity(0.2))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            
                            // バー
                            Rectangle()
                                .fill(item.color)
                                .frame(width: geometry.size.width * CGFloat(maxValue > 0 ? Double(item.value) / Double(maxValue) : 0))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                    .frame(height: 20)
                    
                    // 値
                    Text("\(item.value)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - 週間活動チャート
struct WeeklyActivityChartView: View {
    var dailyCompletions: [Int]
    var maxValue: Int
    var dayColors: [Color]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<dailyCompletions.count, id: \.self) { index in
                let value = dailyCompletions[index]
                
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    // バー
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(dayColors[index])
                        .frame(
                            width: (UIScreen.main.bounds.width - 100) / 7 - DesignSystem.Spacing.xs,
                            height: value > 0 ? CGFloat(value) / CGFloat(maxValue > 0 ? maxValue : 1) * 120 : 5
                        )
                    
                    // 数値
                    Text("\(value)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    // 曜日ラベル
                    Text(dayLabel(index))
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(height: 150)
        .padding(.top, DesignSystem.Spacing.s)
    }
    
    // 曜日ラベルを取得
    private func dayLabel(_ index: Int) -> String {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        return days[index % 7]
    }
}

// MARK: - 複数データの円グラフ
struct DonutChartView: View {
    var segments: [(value: Double, color: Color)]
    var centerText: String
    
    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        ZStack {
            // 円グラフセグメント
            ForEach(0..<segments.count, id: \.self) { index in
                let segment = segments[index]
                let percentage = total > 0 ? segment.value / total : 0
                
                DonutSegment(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: segment.color
                )
            }
            
            // 中央テキスト
            Text(centerText)
                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
    
    // セグメントの開始角度を計算
    private func startAngle(for index: Int) -> Double {
        let precedingTotal = segments.prefix(index).reduce(0) { $0 + $1.value }
        return precedingTotal / total * 360 - 90
    }
    
    // セグメントの終了角度を計算
    private func endAngle(for index: Int) -> Double {
        let includingTotal = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return includingTotal / total * 360 - 90
    }
}

// MARK: - ドーナツチャートセグメント
struct DonutSegment: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    var lineWidth: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - lineWidth / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(degrees: startAngle),
                    endAngle: Angle(degrees: endAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }
}

// MARK: - 折れ線グラフ
struct LineChartView: View {
    var dataPoints: [Int]
    var color: Color
    
    private var maxValue: Int {
        dataPoints.max() ?? 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 折れ線
            Path { path in
                for (index, point) in dataPoints.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                    let y = geometry.size.height - CGFloat(point) / CGFloat(maxValue) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            
            // データポイント
            ForEach(0..<dataPoints.count, id: \.self) { index in
                let point = dataPoints[index]
                let x = geometry.size.width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                let y = geometry.size.height - CGFloat(point) / CGFloat(maxValue) * geometry.size.height
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - プレビュー
struct ChartViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 円グラフ
            PieChartView(value: 75, total: 100, color: DesignSystem.Colors.primary)
                .frame(height: 200)
            
            // 棒グラフアイテム
            HStack {
                BarChartItem(value: 15, total: 30, title: "高", color: DesignSystem.Colors.error)
                BarChartItem(value: 20, total: 30, title: "中", color: DesignSystem.Colors.warning)
                BarChartItem(value: 10, total: 30, title: "低", color: DesignSystem.Colors.info)
            }
            .frame(height: 120)
            
            // 水平棒グラフ
            HorizontalBarChartView(
                items: [
                    ("完了", 45, DesignSystem.Colors.success),
                    ("進行中", 30, DesignSystem.Colors.primary),
                    ("未着手", 25, DesignSystem.Colors.info)
                ],
                maxValue: 45
            )
            .frame(height: 100)
            
            // 週間活動チャート
            WeeklyActivityChartView(
                dailyCompletions: [5, 3, 8, 4, 7, 2, 1],
                maxValue: 8,
                dayColors: [
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.accent,
                    DesignSystem.Colors.accent
                ]
            )
            
            // ドーナツチャート
            DonutChartView(
                segments: [
                    (value: 45, color: DesignSystem.Colors.success),
                    (value: 30, color: DesignSystem.Colors.primary),
                    (value: 25, color: DesignSystem.Colors.info)
                ],
                centerText: "100"
            )
            .frame(height: 200)
            
            // 折れ線グラフ
            LineChartView(
                dataPoints: [5, 12, 8, 14, 10, 15, 18],
                color: DesignSystem.Colors.primary
            )
            .frame(height: 100)
        }
        .padding()
    }
}
