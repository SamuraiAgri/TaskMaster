import Foundation
import SwiftUI

// タグモデル
struct TMTag: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var creationDate: Date = Date()
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
    init(id: UUID = UUID(), name: String, colorHex: String = "#AAAAAA", creationDate: Date = Date(), taskIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.creationDate = creationDate
        self.taskIds = taskIds
    }
    
    // CoreDataのTagからTMTagへの変換
    static func fromCoreData(_ tag: Tag) -> TMTag {
        return TMTag(
            id: tag.id ?? UUID(),
            name: tag.name ?? "",
            colorHex: tag.colorHex ?? "#AAAAAA",
            creationDate: tag.creationDate ?? Date(),
            taskIds: tag.tasks?.compactMap { ($0 as? Task)?.id } ?? []
        )
    }
}

// MARK: - サンプルデータ
extension TMTag {
    static var samples: [TMTag] {
        [
            TMTag(name: "仕事", colorHex: "#5AC8FA"),
            TMTag(name: "個人", colorHex: "#FF9500"),
            TMTag(name: "緊急", colorHex: "#FF3B30"),
            TMTag(name: "会議", colorHex: "#34C759"),
            TMTag(name: "アイデア", colorHex: "#007AFF"),
            TMTag(name: "健康", colorHex: "#FF2D55"),
            TMTag(name: "学習", colorHex: "#5856D6"),
            TMTag(name: "家族", colorHex: "#FF9500")
        ]
    }
}
