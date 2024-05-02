//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    @Published var isDebugModeEnabled: Bool = false
    @Published var isRefreshOnTap: Bool = false
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
                Toggle("Refresh on Tap", isOn: $userSettings.isRefreshOnTap)
                    .onChange(of: userSettings.isRefreshOnTap) { newValue in
                        refreshTapToggle(newValue)
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



