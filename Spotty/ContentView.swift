import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    var body: some View {
        VStack {
            Text("Flight Details")
                .font(.headline)
            Text("Call Sign: \(flight.callSign ?? "N/A")")
            Text("Airline: \(flight.tailNumber ?? "N/A")")
            Text("Type: \(flight.type ?? "N/A")")
            Text("Registration: \(flight.registration ?? "N/A")")
        }
        .padding()
        .navigationBarTitle("Flight \(flight.callSign ?? "Unknown")", displayMode: .inline)
    }
}


struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())

    var body: some View {
        TabView {
            VStack {
                Text("Nearby Flights")
                    .font(.largeTitle)
                    .padding()
                
                if let lastUpdated = flightFetcher.lastUpdated {
                    Text("Last updated: \(lastUpdated, formatter: Self.dateFormatter)")
                        .font(.caption)
                        .padding(.bottom, 1)
                }
                
                if flightFetcher.flights.isEmpty {
                    Text("Fetching flights nearby...")
                } else {
                    NavigationView {
                        List(flightFetcher.flights) { flight in
                            NavigationLink(destination: FlightDetailView(flight: flight)) {
                                Text(flight.callSign ?? "Unknown Call Sign")
                            }
                        }
                        .refreshable {
                            flightFetcher.refreshFlights()
                        }
                        .navigationBarTitleDisplayMode(.inline)
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
            
            // Spotted tab content
            Text("Spotted")
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("Spotted")
                }
            
            // Settings tab content
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(flightFetcher) // Ensure you pass flightFetcher as an environment object
    }
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

struct ContentView_Previews2: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(UserSettings())
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
