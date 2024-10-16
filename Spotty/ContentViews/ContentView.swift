import SwiftUI



struct SearchView: View {
    @State private var searchText: String = ""
    @State private var flight: Flight? = nil
    @State private var cardId = UUID() // Unique ID for CardView
    @State private var isLoading = false
    @ObservedObject private var flightSearch = FlightSearch()

    var body: some View {
        VStack {
            ScrollView {
                SearchBar(text: $searchText, placeholder: "Search by hex or registration") { text in
                    self.searchFlight(text)
                }
                .padding()
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let flight = flight {
                    ImageLoaderView(flight: flight, imageURL: flight.imageURL!)
                        .padding(.horizontal)
                        .id(cardId) // Assign unique ID to CardView
                } else {
                    Text("No flight found")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
        .clipped()
    }

    private func searchFlight(_ searchText: String) {
        isLoading = true
        flightSearch.searchFlight(hexOrReg: searchText) { flight in
            DispatchQueue.main.async {
                isLoading = false
                // Create a new instance of Flight with updated properties
                self.flight = flight
                self.cardId = UUID()
                if flight == nil{
                    self.flight = nil
                }
                return
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onCommit: (String) -> Void

    var body: some View {
        HStack {
            TextField(placeholder, text: $text, onCommit: {
                self.onCommit(self.text)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .disableAutocorrection(true)
            .autocapitalization(.none)
        }
    }
}


struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @EnvironmentObject var userSettings: UserSettings


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
                                let imageURL = flight.imageURL
                                ImageLoaderView(flight: flight, imageURL: imageURL!)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        flightFetcher.refreshFlights()
                        print("-------------------- REFRESHING --------------------")
                    }
                    .clipped()
                }
            }
            .onAppear {
                flightFetcher.startLocationUpdates()
                // Check the user settings and refresh if needed
                if userSettings.isRefreshOnTap {
                    flightFetcher.refreshFlights()
                    print("-------------------- REFRESHING --------------------")
                }
            }
            .tabItem {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text("Nearby")
            }
            SpottedView()
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("Spotted")
                }
            
            SearchView()
                .tabItem{
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }

            NavigationView {
                SettingsView()
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



