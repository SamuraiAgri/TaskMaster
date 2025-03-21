import SwiftUI

struct CalendarView: View {
    // 環境変数
    @EnvironmentObject var taskViewModel: TaskViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    // 状態変数
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
                if calendarViewModel.calendarMode == .month {
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
            .onAppear {
                calendarViewModel.loadEvents()
            }
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
                    .font(Font.system(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .sheet(isPresented: $showingDatePicker) {
                VStack {
                    DatePicker("", selection: Binding(
                        get: { calendarViewModel.currentDate },
                        set: { 
                            calendarViewModel.currentDate = $0
                            // iOS 17以降のonChangeに対応
                            currentMonth = Calendar.current.component(.month, from: $0)
                            currentYear = Calendar.current.component(.year, from: $0)
                        }
                    ), displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                    
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
                calendarViewModel.changeMode(to: .month)
            }) {
                Text("月表示")
                    .font(Font.system(size: DesignSystem.Typography.callout))
                    .foregroundColor(calendarViewModel.calendarMode == .month ? .white : DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(calendarViewModel.calendarMode == .month ? DesignSystem.Colors.primary : DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium, corners: [.topLeft, .bottomLeft])
            }
            
            Button(action: {
                calendarViewModel.changeMode(to: .week)
            }) {
                Text("週表示")
                    .font(Font.system(size: DesignSystem.Typography.callout))
                    .foregroundColor(calendarViewModel.calendarMode == .week ? .white : DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(calendarViewModel.calendarMode == .week ? DesignSystem.Colors.primary : DesignSystem.Colors.background)
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
                        .font(Font.system(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 日付のグリッド
            let daysInMonth = calendarViewModel.daysInMonth(for: calendarViewModel.currentDate)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(date: date)
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
                        .font(Font.system(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 週の日付
            let weekDates = calendarViewModel.daysInWeek(for: calendarViewModel.selectedDate)
            
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    dayCell(date: date)
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // 日付セル
    private func dayCell(date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: calendarViewModel.selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let isCurrentMonth = Calendar.current.component(.month, from: date) == currentMonth
        let day = Calendar.current.component(.day, from: date)
        
        return Button(action: {
            calendarViewModel.selectDate(date)
            calendarViewModel.loadEvents()
        }) {
            VStack {
                Text("\(day)")
                    .font(Font.system(size: DesignSystem.Typography.callout, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor(isSelected: isSelected, isToday: isToday, isCurrentMonth: isCurrentMonth))
                
                // タスク数のインジケーター
                let tasksCount = calendarViewModel.numberOfEvents(for: date)
                if tasksCount > 0 {
                    Text("\(tasksCount)")
                        .font(Font.system(size: DesignSystem.Typography.caption2))
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
                Text(calendarViewModel.selectedDate.formatted(style: .medium))
                    .font(Font.system(size: DesignSystem.Typography.headline, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    calendarViewModel.goToToday()
                }) {
                    Text("今日")
                        .font(Font.system(size: DesignSystem.Typography.subheadline))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            let events = calendarViewModel.eventsForDate(calendarViewModel.selectedDate)
            let tasksForSelectedDate = events.filter { $0.type == .task }
            
            if tasksForSelectedDate.isEmpty {
                VStack {
                    Text("タスクがありません")
                        .font(Font.system(size: DesignSystem.Typography.body))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                    
                    Button(action: {
                        showingNewTaskSheet = true
                    }) {
                        Text("タスクを追加")
                            .font(Font.system(size: DesignSystem.Typography.callout, weight: .medium))
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
                        ForEach(tasksForSelectedDate) { event in
                            if let tmTask = taskViewModel.tasks.first(where: { $0.id == event.id }) {
                                let task = convertToTask(tmTask)
                                NavigationLink(destination: TaskDetailView(taskId: task.id)) {
                                    TaskRowView(task: task)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .background(DesignSystem.Colors.card)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Colors.background)
    }
    
    // Helper: TMTaskをTaskに変換する関数
    private func convertToTask(_ tmTask: TMTask) -> Task {
        let task = Task(context: DataService.shared.viewContext)
        task.id = tmTask.id
        task.title = tmTask.title
        task.taskDescription = tmTask.description
        task.creationDate = tmTask.creationDate
        task.dueDate = tmTask.dueDate
        task.completionDate = tmTask.completionDate
        task.priority = Int16(tmTask.priority.rawValue)
        task.status = tmTask.status.rawValue
        task.isRepeating = tmTask.isRepeating
        task.repeatType = tmTask.repeatType.rawValue
        task.reminderDate = tmTask.reminderDate
        // 注意: この関数はViewContext内のエンティティを作成しますが、
        // コンテキストには保存されていないため、純粋に表示用です
        return task
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
        calendarViewModel.changeMonth(by: value)
        currentMonth = Calendar.current.component(.month, from: calendarViewModel.currentDate)
        currentYear = Calendar.current.component(.year, from: calendarViewModel.currentDate)
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
