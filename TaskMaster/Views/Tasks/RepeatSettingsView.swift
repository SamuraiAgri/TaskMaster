import SwiftUI

struct RepeatSettingsView: View {
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    
    // バインディング
    @Binding var isRepeating: Bool
    @Binding var repeatType: RepeatType
    @Binding var repeatCustomValue: Int?
    
    // 状態変数
    @State private var showingCustomOptions = false
    @State private var customValue: Int = 1
    @State private var customIntervalType: CustomRepeatIntervalType = .days
    
    // カスタム間隔タイプ
    enum CustomRepeatIntervalType: String, CaseIterable, Identifiable {
        case days = "日"
        case weeks = "週"
        case months = "月"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 繰り返し有効化トグル
                Section {
                    Toggle("繰り返し", isOn: $isRepeating)
                        .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                }
                
                if isRepeating {
                    // 繰り返しタイプセクション
                    Section(header: Text("繰り返し頻度")) {
                        VStack {
                            // 繰り返しタイプのピッカー
                            Picker("頻度", selection: $repeatType) {
                                ForEach(RepeatType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .onChange(of: repeatType) { _, newValue in
                                showingCustomOptions = (newValue == .custom)
                                
                                // カスタム選択時、デフォルト値を設定
                                if newValue == .custom && repeatCustomValue == nil {
                                    // カスタム値を初期化
                                    updateCustomRepeatValue()
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            // カスタム設定（カスタム選択時のみ表示）
                            if showingCustomOptions {
                                HStack {
                                    Stepper("毎", value: $customValue, in: 1...99)
                                    
                                    Text("\(customValue)")
                                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body, weight: .bold))
                                        .frame(width: 30)
                                    
                                    Picker("", selection: $customIntervalType) {
                                        ForEach(CustomRepeatIntervalType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(width: 150)
                                }
                                .onChange(of: customValue) { _, _ in
                                    updateCustomRepeatValue()
                                }
                                .onChange(of: customIntervalType) { _, _ in
                                    updateCustomRepeatValue()
                                }
                                .padding(.vertical, DesignSystem.Spacing.xs)
                            }
                        }
                    }
                    
                    // 繰り返しの説明文
                    Section(header: Text("説明")) {
                        Text(repeatDescription)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("繰り返し設定")
            .navigationBarItems(
                trailing: Button("完了") {
                    if !isRepeating {
                        // 繰り返しなしの場合、関連値をリセット
                        repeatType = .none
                        repeatCustomValue = nil
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // 初期状態の設定
                showingCustomOptions = (repeatType == .custom)
                
                if let value = repeatCustomValue {
                    // 既存のカスタム値から状態を復元
                    if value % 30 == 0 {
                        customValue = value / 30
                        customIntervalType = .months
                    } else if value % 7 == 0 {
                        customValue = value / 7
                        customIntervalType = .weeks
                    } else {
                        customValue = value
                        customIntervalType = .days
                    }
                } else {
                    // デフォルト値
                    customValue = 1
                    customIntervalType = .days
                }
            }
        }
    }
    
    // カスタム繰り返し値の更新
    private func updateCustomRepeatValue() {
        // カスタム間隔タイプに応じた日数を計算
        switch customIntervalType {
        case .days:
            repeatCustomValue = customValue
        case .weeks:
            repeatCustomValue = customValue * 7
        case .months:
            repeatCustomValue = customValue * 30
        }
    }
    
    // 繰り返し説明文
    private var repeatDescription: String {
        switch repeatType {
        case .none:
            return "繰り返しなし。このタスクは一度だけ実行されます。"
        case .daily:
            return "毎日繰り返します。完了したら翌日に新しいタスクが作成されます。"
        case .weekdays:
            return "平日（月曜日から金曜日）のみ繰り返します。"
        case .weekly:
            return "毎週同じ曜日に繰り返します。"
        case .monthly:
            return "毎月同じ日に繰り返します。"
        case .yearly:
            return "毎年同じ日に繰り返します。"
        case .custom:
            switch customIntervalType {
            case .days:
                return customValue == 1 ? "毎日繰り返します。" : "\(customValue)日ごとに繰り返します。"
            case .weeks:
                return customValue == 1 ? "毎週繰り返します。" : "\(customValue)週間ごとに繰り返します。"
            case .months:
                return customValue == 1 ? "毎月繰り返します。" : "\(customValue)ヶ月ごとに繰り返します。"
            }
        }
    }
}

struct RepeatSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RepeatSettingsView(
            isRepeating: .constant(true),
            repeatType: .constant(.daily),
            repeatCustomValue: .constant(nil)
        )
    }
}
