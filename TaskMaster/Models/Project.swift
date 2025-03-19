import Foundation
import SwiftUI

// プロジェクトモデル
struct Project: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var colorHex: String
    var creationDate: Date = Date()
    var dueDate: Date?
    var completionDate: Date?
    var taskIds: [UUID] = []
    var parentProjectId: UUID? // サブプロジェクトの場合、親プロジェクトのID
    var subProjectIds: [UUID] = [] // サブプロジェクトのID配列
    
    // 計算プロパティ
    var isCompleted: Bool {
        return completionDate != nil
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: today, to: dueDay)
        return components.day
    }
    
    var isOverdue: Bool {
        guard let daysUntilDue = daysUntilDue, !isCompleted else { return false }
        return daysUntilDue < 0
    }
    
    // 色の取得
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // ハッシュ値の生成
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 初期化メソッド
    init(name: String, description: String? = nil, colorHex: String = "#4A6EB3") {
        self.name = name
        self.description = description
        self.colorHex = colorHex
    }
    
    // 完全な初期化メソッド
    init(id: UUID = UUID(), name: String, description: String? = nil,
         colorHex: String = "#4A6EB3", creationDate: Date = Date(),
         dueDate: Date? = nil, completionDate: Date? = nil,
         taskIds: [UUID] = [], parentProjectId: UUID? = nil,
         subProjectIds: [UUID] = []) {
        
        self.id = id
        self.name = name
        self.description = description
        self.colorHex = colorHex
        self.creationDate = creationDate
        self.dueDate = dueDate
        self.completionDate = completionDate
        self.taskIds = taskIds
        self.parentProjectId = parentProjectId
        self.subProjectIds = subProjectIds
    }
}

// MARK: - サンプルデータ
extension Project {
    static var samples: [Project] {
        [
            Project(
                name: "アプリ開発",
                description: "新規iOSアプリのリリース準備",
                colorHex: "#4A90E2"
            ),
            Project(
                name: "マーケティングキャンペーン",
                description: "第2四半期の販促キャンペーン計画と実行",
                colorHex: "#50C356",
                dueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
            ),
            Project(
                name: "ウェブサイトリニューアル",
                description: "企業ウェブサイトのデザイン刷新とコンテンツ更新",
                colorHex: "#E2A64A"
            ),
            Project(
                name: "人材採用",
                description: "開発チーム拡大のための採用活動",
                colorHex: "#E24A6E",
                dueDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())
            ),
            Project(
                name: "個人タスク",
                description: "個人的なToDoリスト",
                colorHex: "#A64AE2"
            )
        ]
    }
}

// MARK: - 16進数から色への変換
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
