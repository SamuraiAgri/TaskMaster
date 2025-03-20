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
            ContentView()
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
