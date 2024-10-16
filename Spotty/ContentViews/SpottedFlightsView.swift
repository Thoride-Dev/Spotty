//
//  SpottedFlightStore.swift
//  Spotty
//
//  Created by Kush Dalal on 10/15/24.
//

import SwiftUI

struct SpottedFlightsView: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @State private var showingConfirmation = false

    var body: some View {
        NavigationView {
            List {
                ForEach(spottedFlightsStore.spottedFlights) { flight in
                    // Using HStack to place text views side by side
                    HStack {
                        VStack(alignment: .leading) {
                            // Assuming callSign is used for the airline name or flight number
                            Text(flight.callSign ?? "Unknown Flight")
                                .font(.headline)

                            // Displaying the tail number if available
                            Text("Airline: \(flight.tailNumber ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Registration: \(flight.registration ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Aircraft: \(flight.type ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("ICAO: \(flight.id ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Origin: \(flight.origin?.name ?? "N/A") - \(flight.origin?.country_code ?? "N/A")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Destination: \(flight.destination?.name ?? "N/A") - \(flight.destination?.country_code ?? "N/A")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Latitude:  \(flight.position?.latitude ?? 0.00)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Longitude:  \(flight.position?.longitude ?? 0.00)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Date Spotted: \(flight.formattedDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                    }
                }
                .onDelete(perform: deleteItems) // Swipe to delete individual flights
            }
            .navigationTitle("Spotted Flights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingConfirmation = true // Show confirmation for clearing all flights
                    }) {
                        Image(systemName: "trash")
                    }
                    .disabled(spottedFlightsStore.spottedFlights.isEmpty)
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Are you sure?"),
                    message: Text("Do you want to delete all spotted flights?"),
                    primaryButton: .destructive(Text("Delete")) {
                        spottedFlightsStore.clearFlights() // Clears all flights
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // Assuming you have a deleteItems function defined for the onDelete modifier
    private func deleteItems(at offsets: IndexSet) {
        spottedFlightsStore.spottedFlights.remove(atOffsets: offsets)
    }
}
