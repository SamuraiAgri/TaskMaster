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
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    // 週の初め（月曜日）を取得
    var startOfWeek: Date? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        // 月曜日を週の初めとする（日本の週カレンダー方式）
        // 日曜日=1, 月曜日=2, ..., 土曜日=7
        let daysToMonday = weekday == 1 ? -6 : -(weekday - 2)
        return calendar.date(byAdding: .day, value: daysToMonday, to: startOfDay)
    }
    
    // 週の終わり（日曜日）を取得
    var endOfWeek: Date? {
        guard let startOfWeek = startOfWeek else { return nil }
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek)
    }
    
    // 月の初めを取得
    var startOfMonth: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }
    
    // 月の終わりを取得
    var endOfMonth: Date? {
        let calendar = Calendar.current
        guard let startOfMonth = self.startOfMonth else { return nil }
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfMonth)
    }
    
    // 年の初めを取得
    var startOfYear: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)
    }
    
    // 年の終わりを取得
    var endOfYear: Date? {
        let calendar = Calendar.current
        guard let startOfYear = self.startOfYear else { return nil }
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfYear)
    }
    
    // 日数を加算
    func adding(days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
    }
    
    // 週数を加算
    func adding(weeks: Int) -> Date? {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)
    }
    
    // 月数を加算
    func adding(months: Int) -> Date? {
        return Calendar.current.date(byAdding: .month, value: months, to: self)
    }
    
    // 年数を加算
    func adding(years: Int) -> Date? {
        return Calendar.current.date(byAdding: .year, value: years, to: self)
    }
    
    // 2つの日付間の日数を計算
    func daysBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: date)
        if let components = calendar.dateComponents([.day], from: date1, to: date2).day {
            return components
        }
        return 0
    }
    
    // 日付が週末かどうか（土曜日または日曜日）
    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 // 日曜日=1, 土曜日=7
    }
    
    // 平日かどうか（月曜日から金曜日）
    var isWeekday: Bool {
        return !isWeekend
    }
    
    // 相対表示（今日、明日、昨日、または日付）
    var relativeDisplay: String {
        if Calendar.current.isDateInToday(self) {
            return "今日"
        } else if Calendar.current.isDateInTomorrow(self) {
            return "明日"
        } else if Calendar.current.isDateInYesterday(self) {
            return "昨日"
        } else {
            return self.formatted()
        }
    }
    
    // 月の名前を取得（例：1月、2月...）
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    // 曜日の名前を取得（例：月、火...）
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    // 年月表示（例：2025年3月）
    var yearMonthDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
}
