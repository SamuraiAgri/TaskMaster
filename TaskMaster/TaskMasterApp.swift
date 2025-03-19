//
//  TaskMasterApp.swift
//  TaskMaster
//
//  Created by rinka on 2025/03/19.
//

import SwiftUI

@main
struct TaskMasterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
