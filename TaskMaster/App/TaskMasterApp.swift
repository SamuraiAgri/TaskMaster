import SwiftUI

@main
struct TaskMasterApp: App {
    // 環境変数として使用するViewModel
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var tagViewModel = TagViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(taskViewModel)
                .environmentObject(projectViewModel)
                .environmentObject(tagViewModel)
                .environmentObject(homeViewModel)
                .preferredColorScheme(.light) // デフォルトはライトモード
                .onAppear {
                    // アプリ起動時にデータを読み込む
                    taskViewModel.loadTasks()
                    projectViewModel.loadProjects()
                    tagViewModel.loadTags()
                    
                    // ホーム画面データの初期化
                    homeViewModel.initialize(
                        tasks: taskViewModel.tasks,
                        projects: projectViewModel.projects
                    )
                }
        }
    }
}

// メインコンテンツビュー（タブビュー）
struct MainContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            ProjectListView()
                .tabItem {
                    Label("プロジェクト", systemImage: "folder")
                }
                .tag(2)
            
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(3)
            
            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
                .tag(4)
        }
        .accentColor(Color(DesignSystem.Colors.primary))
    }
}

// プレビュー
struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
            .environmentObject(HomeViewModel())
    }
}
