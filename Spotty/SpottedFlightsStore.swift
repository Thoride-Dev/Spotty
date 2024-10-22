//
//  SpottedFlightsStore.swift
//  Spotty
//
//  Created by Patrick Fortin on 4/5/24.
//

import Foundation
import SwiftUI

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
            UserDefaults.standard.set(encoded, forKey: "SpottedFlights")
        }
    }

    private static func loadSpottedFlights() -> [Flight] {
        guard let data = UserDefaults.standard.data(forKey: "SpottedFlights"),
              let decoded = try? JSONDecoder().decode([Flight].self, from: data) else {
            return []
        }
        return decoded
    }
}
