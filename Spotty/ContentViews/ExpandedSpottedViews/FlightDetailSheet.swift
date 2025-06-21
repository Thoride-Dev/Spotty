//
//  FlightDetailSheet.swift
//  Spotty
//
//  Created by Kush Dalal on 6/21/25.
//

import SwiftUI

struct FlightDetailSheet: View {
    let flight: Flight
    let loadedImage: Image?

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                if let image = loadedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                }

                VStack {
                    Text("Registration: \(flight.registration ?? "N/A")")
                    Text("Airline: \(flight.OperatorFlagCode ?? "N/A")")
                    Text("Aircraft Type: \(flight.type ?? "N/A")")
                    Text("Date Spotted: \(formattedDate(flight.dateSpotted))")
                    Text("Location: \(formattedPosition(flight.position))")
                    // Add any other fields here
                }
                .font(.body)

                Spacer()
            }
            .padding()
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedPosition(_ position: Position?) -> String {
        guard let position = position, let lat = position.latitude, let lon = position.longitude else { return "N/A" }
        return String(format: "Lat: %.5f, Lon: %.5f", lat, lon)
    }
}
