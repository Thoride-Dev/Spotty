//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    static let shared = UserSettings() // Singleton instance

    @Published var isDebugModeEnabled: Bool = false
    @Published var isRefreshOnTap: Bool = true
    @Published var radiusKm: Double = 20
}

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Form {
            Toggle("Debug", isOn: $userSettings.isDebugModeEnabled)
                .onChange(of: userSettings.isDebugModeEnabled) { newValue in
                    debugModeToggled(newValue)
                }
            Section(header: Text("Nearby")) {
                Toggle("Refresh on Appear", isOn: $userSettings.isRefreshOnTap)
                    .onChange(of: userSettings.isRefreshOnTap) { newValue in
                        refreshTapToggle(newValue)
                    }
                VStack(alignment: .leading) {
                    Text("Search Radius: \(Int(userSettings.radiusKm)) km")
                        .font(.subheadline)
                    
                    Slider(value: $userSettings.radiusKm, in: 1...40, step: 1)
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    func debugModeToggled(_ isEnabled: Bool) {
        // Perform your action here
        if isEnabled {
            print("Debug mode is now ON")
        } else {
            print("Debug mode is now OFF")
            
        }
    }
    func refreshTapToggle(_ isEnabled: Bool) {
        if isEnabled {
            print("refreshing on tap")
        } else {
            print("NOT refrshing on tap")
        }
    }
}



