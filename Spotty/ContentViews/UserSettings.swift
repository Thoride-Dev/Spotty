//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.

import Foundation
import SwiftUI
import MessageUI

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
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - General Settings
            SettingsCard(title: "General") {
                Toggle("Auto Refresh", isOn: $userSettings.isRefreshOnTap)
                HStack {
                    Text("Search Radius")
                    Spacer()
                    Text(formattedRadius).foregroundColor(.secondary)
                }
                Slider(value: $userSettings.radiusKm, in: 1...40, step: 1)
            }

            // MARK: - Appearance Settings
            SettingsCard(title: "Appearance") {
                Picker("Theme", selection: $userSettings.appearance) {
                    ForEach(Appearance.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("Unit System", selection: $userSettings.unitSystem) {
                    Text("Metric").tag(UnitSystem.metric)
                    Text("Imperial").tag(UnitSystem.imperial)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // MARK: - Support & Legal
            SettingsCard(title: "Support") {
                SettingsButton(title: "Contact Support", icon: "envelope", action: sendEmail)
                SettingsButton(title: "Visit Website", icon: "globe", action: visitWebsite)
                NavigationLink(destination: LegalView()) {
                    SettingsRow(title: "Legal & About", icon: "doc.text")
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }

    var formattedRadius: String {
        let radius = userSettings.radiusKm
        return userSettings.unitSystem == .imperial ? "\(Int(radius * 0.621371)) mi" : "\(Int(radius)) km"
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(.blue)
                Text(title)
                Spacer()
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue)
            Text(title)
        }
    }
}

func sendEmail() {
    let email = "contact@thespottyapp.com"
    let subject = "Spotty Support Request"
    let body = "Hello, I need assistance with Spotty."
    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

    if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"),
       UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
    } else {
        showAlert(title: "No Email App", message: "No email app is installed. Please install an email app to contact support.")
    }
}

func visitWebsite() {
    if let url = URL(string: "https://www.thespottyapp.com"),
       UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
    }
}

func showAlert(title: String, message: String) {
    if let topController = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
        .first?.rootViewController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topController.present(alert, animated: true)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Legal & About")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SectionView(title: "Copyright & Disclaimer") {
                    Text("© 2025 Spotty. All rights reserved.\n\nSpotty is an independent application for aviation enthusiasts. We do not claim ownership of any airline logos, aircraft liveries, or trademarks displayed in the app. These are the property of their respective owners and are used for informational purposes only.\n\nAircraft photos are sourced from **JetPhotos.com**. We do not claim ownership of these images, and all rights remain with the respective photographers.\n\nSpotty is not affiliated with, endorsed by, or officially connected to any airline, aircraft manufacturer, or aviation organization.")
                }

                SectionView(title: "Privacy Policy") {
                    Text("Spotty does not collect, store, or share any personal data unless explicitly stated. Any analytics used are only for app improvements and do not personally identify users. For any concerns, contact us at **contact@thespottyapp.com**.")
                }

                SectionView(title: "Contact Us") {
                    Text("If you have any questions or concerns, feel free to reach out to us at:")
                    Button(action: sendEmail) {
                        Text("contact@thespottyapp.com")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Legal & About")
        .navigationBarTitleDisplayMode(.inline)
    }

    func sendEmail() {
        if let emailURL = URL(string: "mailto:contact@thespottyapp.com") {
            UIApplication.shared.open(emailURL)
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
