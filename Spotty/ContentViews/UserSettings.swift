//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.
//

import Foundation
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { self.rawValue }
}

enum UnitSystem: String, CaseIterable, Identifiable, Codable {
    case metric
    case imperial

    var id: String { self.rawValue }
}

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var isDebugModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isDebugModeEnabled, forKey: "isDebugModeEnabled") }
    }

    @Published var isRefreshOnTap: Bool {
        didSet { UserDefaults.standard.set(isRefreshOnTap, forKey: "isRefreshOnTap") }
    }

    @Published var radiusKm: Double {
        didSet { UserDefaults.standard.set(radiusKm, forKey: "radiusKm") }
    }

    @Published var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance") }
    }

    @Published var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem") }
    }

    init() {
        self.isDebugModeEnabled = UserDefaults.standard.bool(forKey: "isDebugModeEnabled")
        self.isRefreshOnTap = UserDefaults.standard.object(forKey: "isRefreshOnTap") as? Bool ?? true
        self.radiusKm = UserDefaults.standard.object(forKey: "radiusKm") as? Double ?? 20
        self.appearance = Appearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "system") ?? .system
        self.unitSystem = UnitSystem(rawValue: UserDefaults.standard.string(forKey: "unitSystem") ?? "metric") ?? .metric
    }
}

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        Form {
            Section(header: Text("Nearby")) {
                Toggle("Refresh on Appear", isOn: $userSettings.isRefreshOnTap)
                    .onChange(of: userSettings.isRefreshOnTap) { newValue in
                        refreshTapToggle(newValue)
                    }
                
                VStack(alignment: .leading) {
                    Text("Search Radius: \(formattedRadius)")
                        .font(.subheadline)

                    Slider(value: $userSettings.radiusKm, in: 1...40, step: 1)
                }
            }

            Section(header: Text("Appearance")) {
                Picker("Appearance", selection: $userSettings.appearance) {
                    ForEach(Appearance.allCases) { appearance in
                        Text(appearance.rawValue.capitalized).tag(appearance)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button(action: sendEmail) {
                    HStack {
                        Spacer()
                        Text("Contact Support")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    var formattedRadius: String {
        let radius = userSettings.radiusKm
        if userSettings.unitSystem == .imperial {
            return "\(Int(radius * 0.621371)) mi" // Convert km to miles
        } else {
            return "\(Int(radius)) km"
        }
    }
    func sendEmail() {
        if let url = URL(string: "mailto:contact@thespottyapp.com") {
            UIApplication.shared.open(url)
        }
    }
    func refreshTapToggle(_ isEnabled: Bool) {
        if isEnabled {
            print("Refreshing on tap")
        } else {
            print("Not refreshing on tap")
        }
    }
}



struct ColorSchemeTransitionOverlay: View {
    @Binding var isTransitioning: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Rectangle()
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .opacity(isTransitioning ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isTransitioning)
            .ignoresSafeArea()
    }
}






