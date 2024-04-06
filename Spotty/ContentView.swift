import SwiftUI

struct CustomFlightView: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    let flight: Flight
    @State private var isChecked: Bool = false
    private var isFlightSpotted: Bool {
        spottedFlightsStore.spottedFlights.contains(where: { $0.id == flight.id })
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeIn(duration: 0.15)) {
                self.isChecked.toggle()
            }
            if self.isChecked {
                self.spottedFlightsStore.addFlight(self.flight)
            } else {
                self.spottedFlightsStore.removeFlight(self.flight)
            }
        }) {
            HStack {
                // VStack for the call sign and image
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.callSign ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image("preview-airline")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50) // Adjust the size as needed
                }
                .frame(width: 60) // Fix the width for the call sign and image section

                // Fixed-width space before the vertical divider
                Spacer()
                    .frame(width: 20) // Adjust the width as needed
                
                // Vertical Divider
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1, height: 50) // Adjust height as needed
                
                // Fixed-width space after the vertical divider
                Spacer()
                    .frame(width: 20) // Adjust the width as needed
                
                // Right side VStack
                VStack(alignment: .center, spacing: 8) { // Adjust the spacing as needed
                    // Destination Text
                    Text("\(flight.origin ?? "N/A") -> \(flight.destination ?? "N/A")")
                        .font(.largeTitle)
                        
                    // Airplane Type and Registration
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.primary)
                        Text(flight.type ?? "N/A")
                            .foregroundColor(.primary)
                        Image(systemName: "flag")
                        Text(flight.registration ?? "N/A")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)
                
                
            }
            .padding(.vertical, 10) // Vertical padding within the HStack
            .padding(.horizontal, 20)
        
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.white) // Set the background color for the shadow to be effective
        .cornerRadius(10) // Rounded corners
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 400, height: 150) // Set the fixed size for the button's frame
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.clear, lineWidth: 1)
                
                .onAppear {
                    // Initialize isChecked based on whether the flight is spotted
                    self.isChecked = isFlightSpotted
                }
        )
        
    }
    
}

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
                            Text("ICAO: \(flight.id)")
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



struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore

    var body: some View {
        TabView {
            // Nearby flights tab
            VStack {
                if flightFetcher.flights.isEmpty {
                    Text("Fetching flights nearby...")
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(flightFetcher.flights) { flight in
                                CustomFlightView(flight: flight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        flightFetcher.refreshFlights()
                    }
                }
            }
            .onAppear {
                flightFetcher.startLocationUpdates()
            }
            .tabItem {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text("Nearby")
            }

            SpottedFlightsView()
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("Spotted")
                
                .environmentObject(spottedFlightsStore)
                    
                }

            NavigationView {
                SettingsView() // Make sure you have a SettingsView defined or replace this with your settings content
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        // Assuming .light mode is desired across the app; adjust as needed
        .environment(\.colorScheme, .light)
    }
}

struct ClearSpottedFlightsButton: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore

    var body: some View {
        Button("Clear Spotted Flights") {
            spottedFlightsStore.clearFlights()
        }
        .padding()
        .background(Color.red) // Styling for the button
        .foregroundColor(.white)
        .clipShape(Capsule()) // Makes the button have rounded corners
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SpottedFlightsStore())
    }
}
