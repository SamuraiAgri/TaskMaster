import Foundation
import SwiftUI

// 統計カテゴリ
enum StatisticsCategory: String, CaseIterable, Identifiable {
    case tasks = "タスク"
    case projects = "プロジェクト"
    case tags = "タグ"
    case time = "時間"
    
    var id: String { self.rawValue }
}

// プロジェクト進捗
struct ProjectProgress: Identifiable {
    var id: UUID
    var name: String
    var progress: Double
    var color: Color
    var taskCount: Int
}

// タグ分布
struct TagsDistribution: Identifiable {
    var id: UUID
    var name: String
    var count: Int
    var color: Color
}

// 優先度分布
struct PriorityDistribution: Identifiable {
    var id: UUID {
        UUID()
    }
    var priority: Priority
    var count: Int
    var color: Color
}

// ステータス分布
struct StatusDistribution: Identifiable {
    var id: UUID {
        UUID()
    }
    var status: TaskStatus
    var count: Int
    var color: Color
}

// 日次完了
struct DailyCompletion: Identifiable {
    var id: UUID {
        UUID()
    }
    var day: Int
    var date: Date
    var count: Int
}

// 集計期間
enum TMTimeFrame: String, CaseIterable {
    case week = "週"
    case month = "月"
    case year = "年"
    case all = "全期間"
}
