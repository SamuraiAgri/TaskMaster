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
                refreshTrigger.toggle()
            }
        }
        
        // TMProjectからProjectに変換するヘルパーメソッド
        private func getProjectFromTMProject(_ tmProject: TMProject) -> Project {
            if let coreDataProject = DataService.shared.getProject(by: tmProject.id) {
                return coreDataProject
            } else {
                // 実際のプロジェクトが見つからない場合のフォールバック
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
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                Rectangle()
                    .fill(tmProject.color)
                    .frame(width: 4)
                    .cornerRadius(DesignSystem.CornerRadius.small, corners: [.topLeft, .bottomLeft]),
                alignment: .leading
            )
        }
    }

    // 角丸の拡張
    struct TMRoundedCorner: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    // シャドウスタイル
    struct TMShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // プレビュー
    struct ProjectListView_Previews: PreviewProvider {
        static var previews: some View {
            ProjectListView()
                .environmentObject(ProjectViewModel())
                .environmentObject(TaskViewModel())
        }
    }
