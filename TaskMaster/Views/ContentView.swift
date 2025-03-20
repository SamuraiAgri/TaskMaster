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
        MainContentView()
            .environmentObject(taskViewModel)
            .environmentObject(projectViewModel)
            .environmentObject(tagViewModel)
            .environmentObject(homeViewModel)
    }
}

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
        .accentColor(TMDesignSystem.Colors.primary)
    }
}

struct TMDesignSystem {
    struct Colors {
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
