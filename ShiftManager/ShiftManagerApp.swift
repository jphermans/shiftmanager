//
//  ShiftManagerApp.swift
//  ShiftManager
//
//  Created by Jean-Pierre Hermans on 03/01/2025.
//

import SwiftUI

@main
struct ShiftManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
