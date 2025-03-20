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

// 統計情報の構造体
struct TMStatistics {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var completionRate: Double = 0
    var tasksCompletedOnTime: Int = 0
    var onTimeCompletionRate: Double = 0
    var highPriorityTasks: Int = 0
    var mediumPriorityTasks: Int = 0
    var lowPriorityTasks: Int = 0
    var tasksCompletedThisWeek: Int = 0
    var dailyCompletions: [Int] = [0, 0, 0, 0, 0, 0, 0] // 月、火、水、木、金、土、日
    var activeProjects: Int = 0
    var completedProjects: Int = 0
    var activeTags: Int = 0
    
    // CoreDataのStatisticsからTMStatisticsへの変換
    static func fromCoreData(_ statistics: Statistics) -> TMStatistics {
        var tmStats = TMStatistics()
        
        tmStats.totalTasks = Int(statistics.totalTasksCount)
        tmStats.completedTasks = Int(statistics.completedTasksCount)
        tmStats.completionRate = statistics.completionRate
        tmStats.onTimeCompletionRate = statistics.onTimeCompletionRate
        tmStats.highPriorityTasks = Int(statistics.highPriorityCompletedCount)
        tmStats.mediumPriorityTasks = Int(statistics.mediumPriorityCompletedCount)
        tmStats.lowPriorityTasks = Int(statistics.lowPriorityCompletedCount)
        
        return tmStats
    }
}
