//
//  SpottedFlightsStore.swift
//  Spotty
//
//  Created by Patrick Fortin on 4/5/24.
//


import Foundation
import SwiftUI
import Security

/// Simple Keychain helper for storing Data persistently across reinstalls
fileprivate struct KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        // Add new item
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}

class SpottedFlightsStore: ObservableObject {
    @Published var spottedFlights: [Flight] {
        didSet {
            saveSpottedFlights()
        }
    }

    init() {
        self.spottedFlights = SpottedFlightsStore.loadSpottedFlights()
    }
    func clearFlights() {
        self.spottedFlights.removeAll()
    }
    func addFlight(_ flight: Flight) {
        var storableFlight = flight
        storableFlight.dateSpotted = Date()
        self.spottedFlights.append(storableFlight)

    }

    func removeFlight(_ flight: Flight) {
        self.spottedFlights.removeAll { $0.id == flight.id }
        // No need to call save here as didSet will trigger it
    }

    private func saveSpottedFlights() {
        if let encoded = try? JSONEncoder().encode(spottedFlights) {
            KeychainHelper.save(encoded, service: "Spotty", account: "SpottedFlights")
        }
    }

    private static func loadSpottedFlights() -> [Flight] {
        let data: Data?
        if let keychainData = KeychainHelper.read(service: "Spotty", account: "SpottedFlights") {
            data = keychainData
        } else if let defaultsData = UserDefaults.standard.data(forKey: "SpottedFlights") {
            data = defaultsData
        } else {
            data = nil
        }
        guard let stored = data,
              let decoded = try? JSONDecoder().decode([Flight].self, from: stored) else {
            return []
        }
        return decoded
    }
}
