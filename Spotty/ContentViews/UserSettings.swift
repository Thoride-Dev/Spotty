//
//  UserSettings.swift
//  Spotty
//
//  Created by Patrick Fortin on 3/29/24.
//

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

    init() {
        if UserDefaults.standard.object(forKey: "unitSystem") == nil {
            let locale = Locale.current
            let usesMetric = locale.measurementSystem == .metric
            userSettings.unitSystem = usesMetric ? .metric : .imperial
            UserDefaults.standard.set(userSettings.unitSystem.rawValue, forKey: "unitSystem")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // MARK: - Nearby Settings
                    SettingsCard(title: "Nearby Settings") {
                        Toggle("Auto Refresh", isOn: $userSettings.isRefreshOnTap)
                            .onChange(of: userSettings.isRefreshOnTap, perform: refreshTapToggle)

                        VStack(alignment: .leading) {
                            Text("Search Radius: \(formattedRadius)")
                                .font(.subheadline)
                                .padding(.top, 4)

                            Slider(value: $userSettings.radiusKm, in: 1...40, step: 1)
                        }
                    }
                    
                    // MARK: - Appearance Settings
                    SettingsCard(title: "Appearance") {
                        Picker("Appearance", selection: $userSettings.appearance) {
                            ForEach(Appearance.allCases) { appearance in
                                Text(appearance.rawValue.capitalized).tag(appearance)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // MARK: - Additional Settings
                    SettingsCard(title: "Additional Settings") {
                        Picker("Unit System", selection: $userSettings.unitSystem) {
                            Text("Metric").tag(UnitSystem.metric)
                            Text("Imperial").tag(UnitSystem.imperial)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // MARK: - Contact Support
                    Button(action: sendEmail) {
                        HStack {
                            Spacer()
                            Text("Contact Support")
                                .foregroundColor(.blue)
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Visit Website
                    Button(action: visitWebsite) {
                        HStack {
                            Spacer()
                            Text("Visit Website")
                                .foregroundColor(.blue)
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline) // Allows scrolling off screen
        }
    }

    var formattedRadius: String {
        let radius = userSettings.radiusKm
        return userSettings.unitSystem == .imperial ? "\(Int(radius * 0.621371)) mi" : "\(Int(radius)) km"
    }

    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.setToRecipients(["contact@thespottyapp.com"])
            mailComposeVC.setSubject("Spotty Support Request")
            mailComposeVC.setMessageBody("Hello, I need assistance with Spotty.", isHTML: false)

            if let topController = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController {
                topController.present(mailComposeVC, animated: true, completion: nil)
            }
        } else {
            let email = "contact@thespottyapp.com"
            let subject = "Spotty Support Request"
            let body = "Hello, I need assistance with Spotty."
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

            let mailtoURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)")

            if let url = mailtoURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Show alert if no email app is available
                if let topController = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .first?.rootViewController {
                    let alert = UIAlertController(
                        title: "No Email App",
                        message: "No email app is installed. Please install an email app to contact support.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    topController.present(alert, animated: true)
                }
            }
        }
    }
    
    func visitWebsite() {
        if let url = URL(string: "https://www.thespottyapp.com"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func refreshTapToggle(_ isEnabled: Bool) {
        print(isEnabled ? "Refreshing on tap" : "Not refreshing on tap")
    }
}




// MARK: - Settings Card Component
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






