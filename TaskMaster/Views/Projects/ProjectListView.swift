import SwiftUI

struct ProjectListView: View {
    // 環境変数
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    // UI制御プロパティ
    @State private var showingNewProjectSheet = false
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var showingCompletedProjects = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー（表示されている場合）
                if showingSearchBar {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("プロジェクトを検索", text: $searchText)
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                            .onChange(of: searchText) { oldValue, newValue in
                                projectViewModel.searchText = newValue
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                projectViewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.card)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .padding([.horizontal, .top])
                }
                
                // 表示切替トグル
                HStack {
                    Text("進行中")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline, weight: !showingCompletedProjects ? .semibold : .regular))
                        .foregroundColor(!showingCompletedProjects ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    
                    Spacer()
                    
                    Toggle("", isOn: $showingCompletedProjects)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.success))
                    
                    Text("完了済み")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline, weight: showingCompletedProjects ? .semibold : .regular))
                        .foregroundColor(showingCompletedProjects ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                }
                .padding(.horizontal)
                
                // プロジェクトリスト
                if filteredProjects.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.m) {
                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: getProjectFromTMProject(project))) {
                                    ProjectCardItem(tmProject: project)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        projectViewModel.loadProjects()
                    }
                }
            }
            .navigationTitle("プロジェクト")
            .navigationBarItems(
                leading: Button(action: {
                    showingSearchBar.toggle()
                }) {
                    Image(systemName: showingSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                },
                trailing: Button(action: {
                    showingNewProjectSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            )
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingNewProjectSheet) {
                SimpleProjectCreationView()
            }
        }
    }
    
    // 空の状態表示
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            if projectViewModel.searchText.isEmpty {
                Text(showingCompletedProjects ? "完了したプロジェクトはありません" : "プロジェクトはまだありません")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingNewProjectSheet = true
                }) {
                    Text("新しいプロジェクトを作成")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 280)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            } else {
                Text("「\(projectViewModel.searchText)」に一致するプロジェクトはありません")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
    
    // TMProjectからProjectに変換するヘルパーメソッド
    private func getProjectFromTMProject(_ tmProject: TMProject) -> Project {
        if let coreDataProject = DataService.shared.getProject(by: tmProject.id) {
            return coreDataProject
        } else {
            let newProject = Project(context: DataService.shared.viewContext)
            newProject.id = tmProject.id
            newProject.name = tmProject.name
            newProject.projectDescription = tmProject.description
            newProject.colorHex = tmProject.colorHex
            newProject.creationDate = tmProject.creationDate
            newProject.dueDate = tmProject.dueDate
            newProject.completionDate = tmProject.completionDate
            return newProject
        }
    }
    
    // フィルタリングされたプロジェクト
    private var filteredProjects: [TMProject] {
        let filtered = projectViewModel.filteredProjects.filter { project in
            showingCompletedProjects ? project.isCompleted : !project.isCompleted
        }
        return filtered
    }
}

// プロジェクトカードアイテム
struct ProjectCardItem: View {
    var tmProject: TMProject
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            // プロジェクト名とステータス
            HStack {
                Text(tmProject.name)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if tmProject.completionDate != nil {
                    Text("完了")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.s)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(DesignSystem.Colors.success)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
            
            // 説明（あれば）
            if let description = tmProject.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.bottom, DesignSystem.Spacing.xxs)
            }
            
            // タスク数と期限
            HStack {
                let taskCount = tmProject.taskIds.count
                Label {
                    Text("\(taskCount) タスク")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } icon: {
                    Image(systemName: "checklist")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                if let dueDate = tmProject.dueDate {
                    let isOverdue = dueDate < Date() && tmProject.completionDate == nil
                    Label {
                        Text(dueDate.formatted(with: "yyyy/MM/dd"))
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .foregroundColor(isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                            .font(.system(size: 12))
                    }
                }
            }
            
            // 進捗バー
            let progress = projectViewModel.calculateProgress(for: tmProject, tasks: taskViewModel.tasks)
            HStack(spacing: DesignSystem.Spacing.s) {
                ProgressBarView(value: progress, color: tmProject.color, height: 8)
                
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            Rectangle()
                .fill(tmProject.color)
                .frame(width: 4)
                .cornerRadius(DesignSystem.CornerRadius.small, corners: [.topLeft, .bottomLeft]),
            alignment: .leading
        )
    }
}

// シンプルなプロジェクト作成ビュー
struct SimpleProjectCreationView: View {
    // 環境変数
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    // プロジェクトプロパティ
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var colorHex: String = "#4A90E2"
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().adding(days: 14) ?? Date()
    
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("プロジェクト名", text: $name)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("説明 (任意)")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                }
                
                Section(header: Text("カラー")) {
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
                                        .frame(width: 32, height: 32)
                                    
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("期限日")) {
                    Toggle("期限を設定", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("期限日", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新規プロジェクト")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("作成") {
                    createProject()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    // プロジェクト作成
    private func createProject() {
        guard !name.isEmpty else { return }
        
        var project = TMProject(
            name: name,
            description: description.isEmpty ? nil : description,
            colorHex: colorHex
        )
        
        if hasDueDate {
            project.dueDate = dueDate
        }
        
        projectViewModel.addProject(project)
        presentationMode.wrappedValue.dismiss()
    }
}

// 角丸の拡張（UIRectCornerに応じた角丸の適用）
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
