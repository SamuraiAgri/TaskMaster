import Foundation

// MARK: - Date拡張機能
extension Date {
    // 日付のフォーマット
    func formatted(style: DateFormatter.Style = .medium, showTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = showTime ? .short : .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    // カスタムフォーマット
    func formatted(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    // 今日かどうか
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    // 明日かどうか
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    // 昨日かどうか
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    // 今週内かどうか
    var isInThisWeek: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = weekday == 1 ? -6 : -(weekday - 2) // 月曜日を週の初めとする
        
        guard let monday = calendar.date(byAdding: .day, value: daysToMonday, to: today) else {
            return false
        }
        
        guard let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday) else {
            return false
        }
        
        let thisWeekRange = monday..<nextMonday
        return thisWeekRange.contains(self)
    }
    
    // 日付の始まり（00:00:00）
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    // 日付の終わり（23:59:59）
    var endOfDay: Date? {
        var components = DateComponents()
