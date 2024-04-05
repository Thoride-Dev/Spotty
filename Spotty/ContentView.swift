import SwiftUI


struct CustomFlightView: View {
    let flight: Flight
    @State private var isChecked: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(flight.callSign ?? "Unknown Flight")
                    .font(.headline)
                HStack {
                    Text("\(nil ?? "N/A") -> \(nil ?? "N/A")")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "airplane")
                    Text(flight.type ?? "N/A")
                    Spacer()
                    Image(systemName: "flag")
                    Text(flight.registration ?? "N/A")
                }
            }
            
            Spacer()
            
            // Checkbox circle
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .onTapGesture {
                    self.isChecked.toggle()
                }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())

    var body: some View {
        TabView {
            // Nearby flights tab
            VStack {
                if flightFetcher.flights.isEmpty {
                    Text("Fetching flights nearby...")
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

            // Spotted tab content
            Text("Spotted flights will be displayed here.")
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("Spotted")
                }

            // Settings tab content
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
        .environment(\.colorScheme, .light) // Forces light mode for this view
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(UserSettings())
    }
}
