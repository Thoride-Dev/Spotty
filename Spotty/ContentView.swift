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
                    CardView(flight: flight)
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
    @StateObject private var flightFetcher = FlightFetcher()
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
                                CardView(flight: flight)
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

            SpottedFlightsView()
                .tabItem {
                    Image(systemName: "eye.fill")
                    Text("Spotted")
                
                .environmentObject(spottedFlightsStore)
                    
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

struct CardView: View {
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
            VStack(alignment: .center){
                ZStack(alignment: .topLeading) {
                    if let imageURL = flight.imageURL {
                        ImageLoaderView(imageURL: imageURL)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .shadow(radius: 5)
                    } else {
                        Color.gray
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, idealHeight: UIScreen.main.bounds.width * 9 / 16)
                            .clipped()
                            .cornerRadius(30)
                    }
                    
                    //Callsign
                    GeometryReader { geometry in
                        let maxSize = min(geometry.size.width, geometry.size.height) * 0.15
                        let fontSize = min(maxSize, 13.5) // can change font size here
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(radius: 5)
                            .padding() // Add padding to adjust the card size
                            .overlay(
                                VStack {
                                    // callsign display
                                    Text(flight.callSign ?? "N/A")
                                        .font(.system(size: fontSize, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding()
                                }
                            )
                            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3, alignment: .center)
                        // Ensure card adapts to different screen sizes
                    }
                    
                    
                    
                }
                .frame(maxWidth: .infinity)
                
                ZStack(alignment: .bottomLeading){
                    //Logo
                    GeometryReader { geometry in
                        HStack{
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 5)
                                    .frame(width: 50, height: 50) // Adjust the size of the circle
                                Image("\(flight.OperatorFlagCode ?? "preview-airline")")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40) // Adjust the size of the image inside the circle
                            }
                            .padding(EdgeInsets(top: 0, leading: 18, bottom: 25, trailing: 0))
                            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3, alignment: .bottomLeading)
                            
                            ZStack{
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(radius: 5)
                                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 3, alignment: .bottomLeading)
                                    .overlay(
                                        HStack {
                                            // Plane info
                                            Image(systemName: "airplane")
                                                .foregroundColor(.primary)
                                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                                            Text(flight.icaoType ?? "N/A")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                                            Image("airplane.tail")
                                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                                            Text(flight.registration ?? "N/A")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.primary)
                                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                                        }
                                    )
                                    .padding(EdgeInsets(top: -62, leading: -30, bottom: 20, trailing: 20))
                                
                            }
                            
                        }
                        // Ensure card adapts to different screen sizes
                    }
                    
                    GeometryReader { geometry in
                        
                    }
                    
                }
            }
            .padding(EdgeInsets(top: 0, leading: 2, bottom: -10, trailing: 2))
        }
        .onAppear {
            // Initialize isChecked based on whether the flight is spotted
            self.isChecked = isFlightSpotted
        }
        .opacity(self.isChecked ? 0.3 : 1.0) // Adjust the opacity value as needed
    }
    
    struct ImageLoaderView: View {
        let imageURL: URL
        
        func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                completion(UIImage(data: data))
            }.resume()
        }

        @State private var image: UIImage? = nil

        var body: some View {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped() // Clip the image to the frame
                    .cornerRadius(16) // Apply corner radius if desired
                    
            } else {
                ZStack{
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.gray)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    Text("No image...")
                        .onAppear {
                            loadImage(from: imageURL) { loadedImage in
                                DispatchQueue.main.async {
                                    self.image = loadedImage
                                }
                            }
                        }
                    }
                }
            }
        }
}
