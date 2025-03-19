import SwiftUI

struct ProjectListView: View {
    // 環境変数
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    // UI制御プロパティ
    @State private var showingNewProjectSheet = false
    @State private var showingFilterSheet = false
    @State private var showingSearchBar = false
    @State private var selectedProjectId: UUID? = nil
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索・ソートバー
                if showingSearchBar {
                    searchSortBar
                }
                
                // プロジェクトリスト
                if projectViewModel.filteredProjects.isEmpty {
                    emptyStateView
                } else {
                    projectListContent
                }
            }
            .navigationTitle("プロジェクト")
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        showingSearchBar.toggle()
                    }) {
                        Image(systemName: showingSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 18, weight: .semibold))
                    }
                },
                trailing: Button(action: {
                    showingNewProjectSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            )
            .sheet(isPresented: $showingNewProjectSheet) {
                ProjectCreationView()
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(
                    title: Text("並び替え"),
                    buttons: [
                        .default(Text("名前")) {
                            projectViewModel.selectedSortOption = .name
                            projectViewModel.isAscending = true
                        },
                        .default(Text("作成日")) {
                            projectViewModel.selectedSortOption = .creationDate
                            projectViewModel.isAscending = false
                        },
                        .default(Text("期限日")) {
                            projectViewModel.selectedSortOption = .dueDate
                            projectViewModel.isAscending = true
                        },
                        .default(Text("タスク数")) {
                            projectViewModel.selectedSortOption = .taskCount
                            projectViewModel.isAscending = false
                        },
                        .cancel(Text("キャンセル"))
                    ]
                )
            }
            .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
        }
    }
    
    // 検索・ソートバー
    private var searchSortBar: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("プロジェクトを検索", text: $projectViewModel.searchText)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.body))
                
                if !projectViewModel.searchText.isEmpty {
                    Button(action: {
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
            
            // ソートオプション
            HStack {
                Text("並び替え:")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(projectViewModel.selectedSortOption.title)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                Button(action: {
                    projectViewModel.isAscending.toggle()
                }) {
                    Image(systemName: projectViewModel.isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, DesignSystem.Spacing.xs)
        }
        .padding(.horizontal)
        .background(DesignSystem.Colors.background)
    }
    
    // プロジェクトリスト（プロジェクトがある場合）
    private var projectListContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.m) {
                ForEach(projectViewModel.filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectCardItem(project: project)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .refreshable {
            projectViewModel.loadProjects()
            refreshTrigger.toggle()
        }
    }
    
    // 空の状態表示（プロジェクトがない場合）
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            if projectViewModel.searchText.isEmpty {
                Text("プロジェクトがありません")
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
}

// プロジェクトカードアイテム
struct ProjectCardItem: View {
    var project: Project
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            // プロジェクト名とステータス
            HStack {
                Text(project.name)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.headline, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if project.isCompleted {
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
            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.subheadline))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.bottom, DesignSystem.Spacing.xxs)
            }
            
            // タスク数と期限
            HStack {
                Label {
                    Text("\(project.taskIds.count) タスク")
                        .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                } icon: {
                    Image(systemName: "checklist")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                if let dueDate = project.dueDate {
                    Label {
                        Text(dueDate.formatted(with: "yyyy/MM/dd"))
                            .font(DesignSystem.Typography.font(size: DesignSystem.Typography.footnote))
                            .foregroundColor(project.isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(project.isOverdue ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                            .font(.system(size: 12))
                    }
                }
            }
            
            // 進捗バー
            let progress = projectViewModel.calculateProgress(for: project, tasks: taskViewModel.tasks)
            HStack(spacing: DesignSystem.Spacing.s) {
                ProgressBarView(value: progress, color: project.color, height: 8)
                
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.font(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding()
        .background(DesignSystem.Colors.card)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .withShadow(DesignSystem.Shadow.small)
        .overlay(
            Rectangle()
                .fill(project.color)
                .frame(width: 4)
                .cornerRadius(DesignSystem.CornerRadius.small, corners: [.topLeft, .bottomLeft]),
            alignment: .leading
        )
    }
}

// シャドウ拡張
extension View {
    func withShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// シャドウ定義
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// デザインシステム
enum DesignSystem {
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
        
        static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.system(size: size, weight: weight)
        }
    }
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    enum Shadow {
        static let small = DesignSystem.Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = DesignSystem.Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = DesignSystem.Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView()
            .environmentObject(ProjectViewModel())
            .environmentObject(TaskViewModel())
    }
}
