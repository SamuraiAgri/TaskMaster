import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var tagViewModel: TagViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            ProjectListView()
                .tabItem {
                    Label("プロジェクト", systemImage: "folder.fill")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .accentColor(DesignSystem.Colors.primary)
        .onAppear {
            // データの初期ロード
            taskViewModel.loadTasks()
            projectViewModel.loadProjects()
            tagViewModel.loadTags()
            homeViewModel.loadData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(TagViewModel())
            .environmentObject(HomeViewModel())
    }
}
