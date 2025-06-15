import SwiftUI

@available(iOS 18.0, *)
struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @EnvironmentObject var userSettings: UserSettings
    @State private var isFetching: Bool = true
    @State private var search: String = ""

    @State private var fetchingMessage: String = "Fetching flights..."

    let loadingMessages = [
        "Scanning the Skies...",
        "Clearing the Runway for Nearby Flights...",
        "Radar Engaged! Looking for Planes...",
        "Acquiring Targets – I Mean, Flights...",
        "Fasten Your Seatbelt – Fetching Planes!",
        "Tuning into Air Traffic Control...",
        "Preparing for Takeoff – Loading Flights!",
        "Air Traffic Control is tracking flights..."
    ]

    
    var body: some View {
        TabView {
            Tab("Nearby", systemImage: "dot.radiowaves.left.and.right") {
                // Nearby flights tab
                ScrollView {
                    if isFetching {
                        VStack {
                            Text(fetchingMessage)
                                .font(.title3)
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8) // Push to center
                        .onAppear {
                            fetchingMessage = loadingMessages.randomElement() ?? "Fetching flights..."
                        }
                    } else if flightFetcher.flights.isEmpty {
                        VStack {
                            Text("No flights found :(")
                                .font(.title3)
                            Text("Try increasing the radius!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8) // Push to center
                    } else {
                        VStack(spacing: 10) {
                            ForEach(flightFetcher.flights) { flight in
                                let url = flight.imageURL ?? URL(string: "placeholder-image-name")!
                                ImageLoaderView(flight: flight, imageURL: url)
                            }
                        }
                        .padding(.horizontal)

                    }
                }
                .refreshable {
                    flightFetcher.refreshFlights()
                    isFetching = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                       isFetching = false  // Stop fetching indicator
                    }
                    print("-------------------- REFRESHING --------------------")
                }
                //.clipped()
                .onAppear {
                    // Check the user settings and refresh if needed
                    if userSettings.isRefreshOnTap {
                        isFetching = true
                        flightFetcher.refreshFlights()
                        print("-------------------- REFRESHING --------------------")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                       isFetching = false  // Stop fetching indicator
                    }

                }
                .onFirstAppear {
                    flightFetcher.refreshFlights()
                }
            }
            Tab("Spotted", systemImage: "eye.fill") {
                SpottedView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                NavigationStack {
                    SearchView()
                }
            }
        }
        .searchable(text: $search)
        .toolbarBackgroundVisibility(.visible)
        .toolbarBackground(.visible, for: .bottomBar)
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

public struct OnFirstAppearModifier: ViewModifier {

    private let onFirstAppearAction: () -> ()
    @State private var hasAppeared = false
    
    public init(_ onFirstAppearAction: @escaping () -> ()) {
        self.onFirstAppearAction = onFirstAppearAction
    }
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                onFirstAppearAction()
            }
    }
}

extension View {
    func onFirstAppear(_ onFirstAppearAction: @escaping () -> () ) -> some View {
        return modifier(OnFirstAppearModifier(onFirstAppearAction))
    }
}

@available(iOS 18.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SpottedFlightsStore())
    }
}
