//
//  SpottyApp.swift
//  Spotty
//
//  Created by Kush Dalal on 3/28/24.
//
import SwiftUI

@main
@available(iOS 17.0, *)
struct SpottyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var userSettings = UserSettings.shared
    @StateObject var spottedFlightsStore = SpottedFlightsStore()
    @StateObject var flightFetcher = FlightFetcher(userSettings: UserSettings.shared)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(userSettings)
                .environmentObject(spottedFlightsStore)
                .environmentObject(flightFetcher) 
                .preferredColorScheme(colorScheme(for: userSettings.appearance))
        }
    }

    private func colorScheme(for appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

