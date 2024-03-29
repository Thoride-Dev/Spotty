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
    @StateObject private var flightFetcher = FlightFetcher()

    var body: some View {
        TabView {
            // x tab content
            VStack {
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
                        .navigationBarTitle("Nearby Flights")
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
            Text("Settings")
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .environmentObject(flightFetcher) // If you want to use flightFetcher across tabs
        .environment(\.colorScheme, .light) // Forces light mode for this view
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
