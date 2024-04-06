//
//  SpottyApp.swift
//  Spotty
//
//  Created by Kush Dalal on 3/28/24.
//

import SwiftUI

@main
struct SpottyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var userSettings = UserSettings()
    var spottedFlightsStore = SpottedFlightsStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(userSettings) // Correctly pass UserSettings as an environment object here
                .environmentObject(spottedFlightsStore)
        }
    }
}




