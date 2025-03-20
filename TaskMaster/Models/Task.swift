import Foundation

// 優先度の列挙型
enum Priority: Int, Codable, CaseIterable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "Info"
        case .medium:
            return "Warning"
        case .high:
            return "Error"
        }
    }
}

// 繰り返しの種類
enum RepeatType: String, Codable, CaseIterable, Identifiable {
    case none = "なし"
    case daily = "毎日"
    case weekdays = "平日"
    case weekly = "毎週"
    case monthly = "毎月"
    case yearly = "毎年"
    case custom = "カスタム"
    
    var id: String { rawValue }
}

// タスクの状態
enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "未着手"
    case inProgress = "進行中"
    case completed = "完了"
    case postponed = "延期"
    case cancelled = "キャンセル"
    
    var id: String { rawValue }
}

// タスクモデル
struct TMTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var creationDate: Date = Date()
    var dueDate: Date?
    var completionDate: Date?
    var priority: Priority
    var status: TaskStatus
    var projectId: UUID?
    var tagIds: [UUID] = []
    var isRepeating: Bool = false
    var repeatType: RepeatType = .none
    var repeatCustomValue: Int? // カスタム繰り返しの場合の値
    var reminderDate: Date?
    var parentTaskId: UUID? // サブタスクの場合、親タスクのID
    var subTaskIds: [UUID] = [] // サブタスクのID配列
    
    // 計算プロパティ
    var isDue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .completed
    }
    
    var isCompleted: Bool {
        return status == .completed
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
        guard let daysUntilDue = daysUntilDue else { return false }
        return daysUntilDue < 0 && status != .completed
    }
    
    // ハッシュ値の生成
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 初期化メソッド - 最小限の情報で作成
    init(title: String, priority: Priority = .medium, status: TaskStatus = .notStarted) {
        self.title = title
        self.priority = priority
        self.status = status
    }
    
    // 完全な初期化メソッド
    init(id: UUID = UUID(), title: String, description: String? = nil,
         creationDate: Date = Date(), dueDate: Date? = nil, completionDate: Date? = nil,
         priority: Priority = .medium, status: TaskStatus = .notStarted,
         projectId: UUID? = nil, tagIds: [UUID] = [], isRepeating: Bool = false,
         repeatType: RepeatType = .none, repeatCustomValue: Int? = nil,
         reminderDate: Date? = nil, parentTaskId: UUID? = nil, subTaskIds: [UUID] = []) {
        
        self.id = id
        self.title = title
        self.description = description
        self.creationDate = creationDate
        self.dueDate = dueDate
        self.completionDate = completionDate
        self.priority = priority
        self.status = status
        self.projectId = projectId
        self.tagIds = tagIds
        self.isRepeating = isRepeating
        self.repeatType = repeatType
        self.repeatCustomValue = repeatCustomValue
        self.reminderDate = reminderDate
        self.parentTaskId = parentTaskId
        self.subTaskIds = subTaskIds
    }
}

// MARK: - サンプルデータ
extension TMTask {
    static var samples: [TMTask] {
        [
            TMTask(
                title: "プロジェクト提案書の作成",
                description: "クライアントXYZ向けの新規プロジェクト提案書を作成する",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                priority: .high,
                status: .inProgress
            ),
            TMTask(
                title: "週次ミーティングの準備",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                priority: .medium,
                status: .notStarted,
                isRepeating: true,
                repeatType: .weekly
            ),
            TMTask(
                title: "メールの返信",
                description: "取引先からの問い合わせに返信する",
                dueDate: Date(),
                priority: .low,
                status: .notStarted
            ),
            TMTask(
                title: "アプリのバグ修正",
                description: "ログイン画面のクラッシュ問題を修正",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                priority: .high,
                status: .completed,
                completionDate: Date()
            ),
            TMTask(
                title: "買い物リスト作成",
                priority: .low,
                status: .notStarted
            )
        ]
    }
}
