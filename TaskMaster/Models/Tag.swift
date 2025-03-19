import Foundation
import SwiftUI

// タグモデル
struct Tag: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var taskIds: [UUID] = []
    
    // 色の取得
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    // ハッシュ値の生成
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 初期化メソッド
    init(name: String, colorHex: String = "#AAAAAA") {
        self.name = name
        self.colorHex = colorHex
    }
    
    // 完全な初期化メソッド
    init(id: UUID = UUID(), name: String, colorHex: String = "#AAAAAA", taskIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.taskIds = taskIds
    }
}

// MARK: - サンプルデータ
extension Tag {
    static var samples: [Tag] {
        [
            Tag(name: "仕事", colorHex: "#5AC8FA"),
            Tag(name: "個人", colorHex: "#FF9500"),
            Tag(name: "緊急", colorHex: "#FF3B30"),
            Tag(name: "会議", colorHex: "#34C759"),
            Tag(name: "アイデア", colorHex: "#007AFF"),
            Tag(name: "健康", colorHex: "#FF2D55"),
            Tag(name: "学習", colorHex: "#5856D6"),
            Tag(name: "家族", colorHex: "#FF9500")
        ]
    }
}
