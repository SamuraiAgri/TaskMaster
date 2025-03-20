//
//  ContentView.swift
//  TaskMaster
//
//  Created by rinka on 2025/03/19.
//

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
        .accentColor(DesignSystem.Colors.primary)
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
