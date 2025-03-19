import SwiftUI

/// アプリケーション全体で使用される定数を定義
enum AppConstants {
    /// アプリケーション情報
    enum App {
        static let name = "TaskMaster"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// ユーザーデフォルトのキー
    enum UserDefaultsKeys {
        static let firstLaunch = "firstLaunch"
        static let lastOpenedDate = "lastOpenedDate"
        static let tasksKey = "tasks"
        static let projectsKey = "projects"
        static let tagsKey = "tags"
        static let settingsKey = "settings"
    }
    
    /// 通知関連の定数
    enum Notifications {
        static let taskReminderIdentifierPrefix = "task-"
        static let dailyReminderIdentifier = "daily-reminder"
        static let weeklyReportIdentifier = "weekly-report"
        static let overdueTasksIdentifier = "overdue-tasks"
    }
    
    /// 時間関連の定数
    enum Time {
        static let secondsInMinute: Double = 60
        static let minutesInHour: Double = 60
        static let hoursInDay: Double = 24
        static let daysInWeek: Double = 7
        
        static let secondsInHour: Double = secondsInMinute * minutesInHour
        static let secondsInDay: Double = secondsInHour * hoursInDay
        static let secondsInWeek: Double = secondsInDay * daysInWeek
    }
    
    /// URL関連の定数
    enum URLs {
        static let appWebsite = "https://www.taskmaster-app.com"
        static let privacyPolicy = "https://www.taskmaster-app.com/privacy"
        static let termsOfService = "https://www.taskmaster-app.com/terms"
        static let supportEmail = "support@taskmaster-app.com"
    }
}

/// デザインシステムの定義
enum DesignSystem {
    /// アプリのカラーパレット
    enum Colors {
        static let primary = Color(hex: "#4A90E2") ?? .blue
        static let secondary = Color(hex: "#9B9B9B") ?? .gray
        static let accent = Color(hex: "#50C356") ?? .green
        static let error = Color(hex: "#E24A6E") ?? .red
        static let warning = Color(hex: "#E2A64A") ?? .orange
        static let success = Color(hex: "#50C356") ?? .green
        static let info = Color(hex: "#4A90E2") ?? .blue
        
        static let background = Color(hex: "#F9F9F9") ?? .white
        static let card = Color.white
        
        static let textPrimary = Color(hex: "#333333") ?? .black
        static let textSecondary = Color(hex: "#777777") ?? .gray
    }
    
    /// タイポグラフィサイズ
    enum Typography {
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
        
        /// フォントを生成
        static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.system(size: size, weight: weight)
        }
    }
    
    /// スペーシング
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    /// 角丸の半径
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    /// シャドウ定義
    enum Shadow {
        static let small = TaskMaster.Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = TaskMaster.Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = TaskMaster.Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    /// アニメーション
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    /// UIコンポーネントサイズ
    enum ComponentSize {
        static let buttonHeight: CGFloat = 44
        static let inputHeight: CGFloat = 44
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }
}

/// シャドウ構造体
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
