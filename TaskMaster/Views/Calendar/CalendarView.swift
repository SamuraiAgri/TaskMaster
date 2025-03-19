import SwiftUI

struct CalendarView: View {
    // 環境変数
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    // 状態変数
    @State private var selectedDate: Date = Date()
    @State private var calendarMode: CalendarMode = .month
    @State private var showingNewTaskSheet = false
    @State private var showingDatePicker = false
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    
    // 日付のフォーマッタ
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
    
    // 曜日ラベル
    private let weekdaySymbols = ["月", "火", "水", "木", "金", "土", "日"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // カレンダーヘッダー
                calendarHeader
                
                // カレンダーモード切替
                calendarModeSelector
                
                // カレンダーコンテンツ
                if calendarMode == .month {
                    monthCalendarView
                } else {
                    weekCalendarView
                }
                
                // 選択された日付のタスク
                selectedDateTasksView
            }
            .navigationTitle("カレンダー")
            .navigationBarItems(trailing:
                Button(action: {
                    showingNewTaskSheet = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingNewTaskSheet) {
                TaskCreationView()
            }
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
        }
    }
    
    // カレンダーヘッダー
    private var calendarHeader: some View {
        HStack {
            Button(action: {
                moveMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            Spacer()
            
            Button(action: {
                showingDatePicker = true
            }) {
                Text(formattedYearMonth)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .sheet(isPresented: $showingDatePicker) {
                VStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .onChange(of: selectedDate) { newValue in
                            currentMonth = Calendar.current.component(.month, from: newValue)
                            currentYear = Calendar.current.component(.year, from: newValue)
                        }
                    
                    Button("完了") {
                        showingDatePicker = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .padding()
                }
                .presentationDetents([.medium])
            }
            
            Spacer()
            
            Button(action: {
                moveMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
    }
    
    // カレンダーモード切替
    private var calendarModeSelector: some View {
        HStack(spacing: 0) {
            Button(action: {
                calendarMode = .month
            }) {
                Text("月表示")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout))
                    .foregroundColor(calendarMode == .month ? .white : DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(calendarMode == .month ? DesignSystem.Colors.primary : DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium, corners: [.topLeft, .bottomLeft])
            }
            
            Button(action: {
                calendarMode = .week
            }) {
                Text("週表示")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout))
                    .foregroundColor(calendarMode == .week ? .white : DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(calendarMode == .week ? DesignSystem.Colors.primary : DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium, corners: [.topRight, .bottomRight])
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DesignSystem.Spacing.s)
    }
    
    // 月カレンダー表示
    private var monthCalendarView: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // 曜日のヘッダー
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 日付のグリッド
            let daysInMonth = daysInMonth()
            let firstWeekday = firstWeekdayOfMonth()
            let totalCells = daysInMonth + firstWeekday - 1
            let rows = (totalCells - 1) / 7 + 1
            
            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { column in
                            let index = row * 7 + column
                            let day = index - firstWeekday + 2
                            
                            if day > 0 && day <= daysInMonth {
                                dayCell(day: day)
                            } else {
                                // 空のセル
                                Text("")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                    .frame(height: 60)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // 週カレンダー表示
    private var weekCalendarView: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // 曜日のヘッダー
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 週の日付
            let weekDates = datesOfSelectedWeek()
            
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    let date = weekDates[index]
                    let day = Calendar.current.component(.day, from: date)
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    let isCurrentMonth = Calendar.current.component(.month, from: date) == currentMonth
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack {
                            Text("\(day)")
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isSelected || isToday ? .bold : .regular))
                                .foregroundColor(dayTextColor(isSelected: isSelected, isToday: isToday, isCurrentMonth: isCurrentMonth))
                            
                            // タスク数のインジケーター
                            let tasksCount = taskViewModel.tasksForDate(date).count
                            if tasksCount > 0 {
                                Text("\(tasksCount)")
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignSystem.Colors.primary)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                        .overlay(
                            Circle()
                                .fill(isToday ? DesignSystem.Colors.error : Color.clear)
                                .frame(width: 5, height: 5)
                                .offset(y: 12),
                            alignment: .bottom
                        )
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // 日付セル
    private func dayCell(day: Int) -> some View {
        let date = dateForDay(day)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        
        return Button(action: {
            selectedDate = date
        }) {
            VStack {
                Text("\(day)")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : (isToday ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary))
                
                // タスク数のインジケーター
                let tasksCount = taskViewModel.tasksForDate(date).count
                if tasksCount > 0 {
                    Text("\(tasksCount)")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption2))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .overlay(
                Circle()
                    .fill(isToday ? DesignSystem.Colors.error : Color.clear)
                    .frame(width: 5, height: 5)
                    .offset(y: 12),
                alignment: .bottom
            )
        }
    }
    
    // 選択された日付のタスク一覧
    private var selectedDateTasksView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text(selectedDate.formatted(style: .medium))
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("今日")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            let tasksForSelectedDate = taskViewModel.tasksForDate(selectedDate)
            
            if tasksForSelectedDate.isEmpty {
                VStack {
                    Text("タスクがありません")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                    
                    Button(action: {
                        showingNewTaskSheet = true
                    }) {
                        Text("タスクを追加")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.callout, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        ForEach(tasksForSelectedDate) { task in
                            NavigationLink(destination: TaskDetailView(taskId: task.id)) {
                                TaskRowView(task: task)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Colors.background)
    }
    
    // ヘルパーメソッド
    
    // 年月の表示用フォーマット
    private var formattedYearMonth: String {
        let components = DateComponents(year: currentYear, month: currentMonth)
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    // 月を移動する
    private func moveMonth(by value: Int) {
        var components = DateComponents()
        components.month = value
        
        if let newDate = Calendar.current.date(byAdding: components, to: selectedDate) {
            selectedDate = newDate
            currentMonth = Calendar.current.component(.month, from: selectedDate)
            currentYear = Calendar.current.component(.year, from: selectedDate)
        }
    }
    
    // 月の日数を取得
    private func daysInMonth() -> Int {
        let components = DateComponents(year: currentYear, month: currentMonth)
        guard let date = Calendar.current.date(from: components),
              let range = Calendar.current.range(of: .day, in: .month, for: date) else {
            return 0
        }
        return range.count
    }
    
    // 月の最初の曜日を取得（1 = 月曜日, ... 7 = 日曜日）
    private func firstWeekdayOfMonth() -> Int {
        let components = DateComponents(year: currentYear, month: currentMonth, day: 1)
        guard let date = Calendar.current.date(from: components) else {
            return 1
        }
        
        // 日曜始まりを月曜始まりに変換
        var weekday = Calendar.current.component(.weekday, from: date)
        weekday = (weekday + 5) % 7 + 1  // 1=月曜日、7=日曜日になるよう変換
        return weekday
    }
    
    // 指定された日の日付を取得
    private func dateForDay(_ day: Int) -> Date {
        let components = DateComponents(year: currentYear, month: currentMonth, day: day)
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // 選択された日付を含む週の日付を取得
    private func datesOfSelectedWeek() -> [Date] {
        // 週の開始日（月曜日）を取得
        let calendar = Calendar.current
        var selectedWeekDay = calendar.component(.weekday, from: selectedDate)
        selectedWeekDay = selectedWeekDay == 1 ? 7 : selectedWeekDay - 1 // 月曜日=1, 日曜日=7
        
        let daysToMonday = selectedWeekDay - 1
        guard let mondayDate = calendar.date(byAdding: .day, value: -daysToMonday, to: selectedDate) else {
            return []
        }
        
        var weekDates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: mondayDate) {
                weekDates.append(date)
            }
        }
        
        return weekDates
    }
    
    // 日付の文字色を決定
    private func dayTextColor(isSelected: Bool, isToday: Bool, isCurrentMonth: Bool) -> Color {
        if isSelected {
            return DesignSystem.Colors.primary
        } else if isToday {
            return DesignSystem.Colors.error
        } else if !isCurrentMonth {
            return DesignSystem.Colors.textSecondary.opacity(0.5)
        } else {
            return DesignSystem.Colors.textPrimary
        }
    }
}

// カレンダーモード
enum CalendarMode {
    case month
    case week
}

// Date拡張
extension Date {
    // 指定された日数を加算した日付を返す
    func adding(days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
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
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(TaskViewModel())
    }
}
