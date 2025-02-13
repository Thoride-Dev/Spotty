import SwiftUI



@available(iOS 17.0, *)
struct ContentView: View {
    @StateObject private var flightFetcher = FlightFetcher(userSettings: UserSettings())
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @EnvironmentObject var userSettings: UserSettings
    @State private var isFetching: Bool = true

    var body: some View {
        TabView {
            // Nearby flights tab
            ScrollView {
                if isFetching {
                    VStack {
                        Text("Fetching nearby flights...")
                            .font(.title3)
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8) // Push to center
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
                            let imageURL = flight.imageURL
                            ImageLoaderView(flight: flight, imageURL: imageURL!)
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
        .toolbarBackground(.hidden, for: .tabBar)
        .onAppear {
            let apparence = UITabBarAppearance()
            apparence.configureWithTransparentBackground()
            if #available(iOS 15.0, *) {UITabBar.appearance().scrollEdgeAppearance = apparence}
        }
        
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

@available(iOS 17.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SpottedFlightsStore())
    }
}



