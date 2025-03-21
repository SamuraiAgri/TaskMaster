import SwiftUI

struct ProjectCreationView: View {
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    // プロジェクトプロパティ
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var colorHex: String = "#4A90E2"
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().adding(days: 14) ?? Date()
    @State private var showingDueDatePicker: Bool = false
    
    // カラーパレット
    private let colorPalette = [
        "#4A90E2", // 青
        "#50C356", // 緑
        "#E2A64A", // オレンジ
        "#E24A6E", // 赤
        "#9B59B6", // 紫
        "#3498DB", // 水色
        "#1ABC9C", // ティール
        "#F39C12", // 黄色
        "#E74C3C", // 赤
        "#34495E"  // 紺
    ]
    
    // バリデーション
    @State private var nameError: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    // プロジェクト名入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("プロジェクト名")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("新しいプロジェクト", text: $name)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(nameError != nil ? DesignSystem.Colors.error : Color.clear, lineWidth: 1)
                            )
                            .onChange(of: name) { _, _ in
                                validateName()
                            }
                        
                        if let error = nameError {
                            Text(error)
                                .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                    
                    // 説明入力
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("説明（任意）")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: $description)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .padding()
                            .frame(minHeight: 120)
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    // カラー選択
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("カラー")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        colorPaletteView
                    }
                    
                    // 期限日設定
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Toggle("期限日", isOn: $hasDueDate)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        
                        if hasDueDate {
                            HStack {
                                Text(dueDate.formatted())
                                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingDueDatePicker.toggle()
                                }) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            
                            if showingDueDatePicker {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .labelsHidden()
                                    .padding()
                                    .background(DesignSystem.Colors.card)
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                        }
                    }
                    
                    // 作成ボタン
                    Button(action: createProject) {
                        Text("プロジェクトを作成")
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? DesignSystem.Colors.primary.opacity(0.5) : DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .disabled(name.isEmpty)
                    .padding(.top, DesignSystem.Spacing.m)
                }
                .padding()
            }
            .navigationTitle("新規プロジェクト")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
        }
    }
    
    // カラーパレット表示
    private var colorPaletteView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(colorPalette, id: \.self) { hex in
                Button(action: {
                    colorHex = hex
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex) ?? .blue)
                            .frame(width: 40, height: 40)
                        
                        if colorHex == hex {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
            
            // ランダムカラーオプション
            Button {
                colorHex = projectViewModel.randomColor()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "dice")
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    // プロジェクト名の検証
    private func validateName() {
        if name.isEmpty {
            nameError = "プロジェクト名は必須です"
        } else {
            nameError = nil
        }
    }
    
    // プロジェクト作成
    private func createProject() {
        // バリデーション
        validateName()
        if nameError != nil {
            return
        }
        
        // プロジェクトの作成
        var project = TMProject(
            name: name,
            description: description.isEmpty ? nil : description,
            colorHex: colorHex
        )
        
        // 期限日の設定
        if hasDueDate {
            project.dueDate = dueDate
        }
        
        // 保存
        projectViewModel.addProject(project)
        
        // フォームを閉じる
        presentationMode.wrappedValue.dismiss()
    }
}

struct ProjectCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectCreationView()
            .environmentObject(ProjectViewModel())
    }
}
