import SwiftUI

// MARK: - 色の拡張機能
extension Color {
    // UIカラーに変換
    func uiColor() -> UIColor {
        let components = self.components()
        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }
    
    // RGB成分の取得
    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        
        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
    
    // ランダムな色の生成
    static func random(brightness: CGFloat = 0.8) -> Color {
        let hue = CGFloat.random(in: 0...1)
        return Color(hue: Double(hue), saturation: Double(0.5), brightness: Double(brightness), opacity: 1)
    }
    
    // 明るさの調整
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        let components = self.components()
        return Color(
            red: min(components.r + percentage, 1.0),
            green: min(components.g + percentage, 1.0),
            blue: min(components.b + percentage, 1.0),
            opacity: components.a
        )
    }
    
    // 暗さの調整
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let components = self.components()
        return Color(
            red: max(components.r - percentage, 0.0),
            green: max(components.g - percentage, 0.0),
            blue: max(components.b - percentage, 0.0),
            opacity: components.a
        )
    }
    
    // 16進数表現の取得
    func hexString() -> String {
        let components = self.components()
        return String(
            format: "#%02X%02X%02X",
            Int(components.r * 255),
            Int(components.g * 255),
            Int(components.b * 255)
        )
    }
    
    // コントラスト色の取得（文字色などに最適）
    func contrastColor() -> Color {
        let components = self.components()
        let brightness = ((components.r * 299) + (components.g * 587) + (components.b * 114)) / 1000
        return brightness > 0.5 ? .black : .white
    }
}

// MARK: - カラーセット
extension Color {
    // 優先度の色
    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return DesignSystem.Colors.error
        case .medium:
            return DesignSystem.Colors.warning
        case .low:
            return DesignSystem.Colors.info
        }
    }
    
    // タスク状態の色
    static func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .notStarted:
            return DesignSystem.Colors.info
        case .inProgress:
            return DesignSystem.Colors.primary
        case .completed:
            return DesignSystem.Colors.success
        case .postponed:
            return DesignSystem.Colors.warning
        case .cancelled:
            return DesignSystem.Colors.error
        }
    }
}
