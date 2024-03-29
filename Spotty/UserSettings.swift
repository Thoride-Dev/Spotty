//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    @Published var isDebugModeEnabled: Bool = true
}

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Form {
            Toggle("Debug", isOn: $userSettings.isDebugModeEnabled)
                .onChange(of: userSettings.isDebugModeEnabled) { newValue in
                    debugModeToggled(newValue)
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
}



