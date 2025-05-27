//
//  SearchView.swift
//  Spotty
//
//  Created by Kush Dalal on 2/12/25.
//

import SwiftUI
import WebKit
import CoreLocation

struct AirportOption: Identifiable, Hashable {
    let id = UUID()
    let icao: String
    let name: String
}

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var flight: Flight? = nil
    @State private var cardId = UUID()
    @State private var isLoading = false
    @ObservedObject private var flightSearch = FlightSearch()
    @State private var showWebView = false
    @State private var airportOptions: [AirportOption] = []
    @State private var selectedAirport: AirportOption? = nil
    @EnvironmentObject var flightFetcher: FlightFetcher

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    if !showWebView {
                        Text("Search")
                            .font(.title)
                            .foregroundColor(Color(UIColor.label))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()

                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Search by hex or registration", text: $searchText)
                                .onSubmit {
                                    if !searchText.isEmpty {
                                        searchFlight(searchText)
                                    }
                                }
                        }
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 5)
                        .background(RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.quaternaryLabel)))
                        .padding([.horizontal, .bottom])

                        if isLoading {
                            ProgressView()
                                .padding()
                        } else if let flight = flight {
                            ImageLoaderView(flight: flight, imageURL: flight.imageURL!)
                                .padding(.horizontal)
                                .id(cardId)
                        } else {
                            Text("No flight found")
                                .foregroundColor(.gray)
                                .padding()
                        }

                        Spacer()

                        Text("Tools")
                            .font(.title)
                            .foregroundColor(Color(UIColor.label))
                            .bold()
                            .frame(maxWidth: geometry.size.width * 0.9, alignment: .leading)

                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: geometry.size.width * 0.9, height: 1)
                            .foregroundColor(Color(.systemGray4))

                        HStack {
                            Button("Where to Spot", systemImage: "location.fill.viewfinder") {
                                showWebView.toggle()
                            }
                            .font(.title2)
                            .padding()
                            .buttonStyle(.bordered)

                            Button("Live ATC", systemImage: "waveform.badge.microphone") {
                                guard let selected = selectedAirport,
                                      let url = URL(string: "https://www.liveatc.net/search/?icao=\(selected.icao)") else {
                                    return
                                }
                                UIApplication.shared.open(url)
                            }
                            .font(.title2)
                            .padding()
                            .buttonStyle(.bordered)
                        }

                        if !airportOptions.isEmpty {
                            Picker("Nearest Airports", selection: $selectedAirport) {
                                ForEach(airportOptions) { option in
                                    Text("\(option.name) (\(option.icao))").tag(option as AirportOption?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                        }
                    }
                }
                .onAppear {
                    if let userLocation = flightFetcher.userLocation {
                        print("Location used for nearest airport: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                        fetchNearestAirportsFromCSV(limit: 5, using: userLocation) { options in
                            DispatchQueue.main.async {
                                self.airportOptions = options
                                self.selectedAirport = options.first
                            }
                        }
                    } else {
                        print("No user location available in FlightFetcher")
                    }
                }

                .ignoresSafeArea(.keyboard)

                if showWebView {
                    GeometryReader { geometry in
                        let airportQuery = selectedAirport?.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let url = URL(string: "https://www.spotterguide.net/?s=\(airportQuery)")!

                        WebView(url: url, showWebView: $showWebView)
                            .frame(width: geometry.size.width, height: geometry.size.height - 3)
                            .transition(.move(edge: .leading))
                            .zIndex(1)
                            .onTapGesture {
                                withAnimation {
                                    showWebView = false
                                }
                            }
                    }
                    .transition(.move(edge: .trailing))
                }

            }
        }
    }

    private func searchFlight(_ searchText: String) {
        isLoading = true
        flightSearch.searchFlight(hexOrReg: searchText) { flight in
            DispatchQueue.main.async {
                isLoading = false
                self.flight = flight
                self.cardId = UUID()
            }
        }
    }
}

struct WebView: View {
    let url: URL
    @Binding var showWebView: Bool

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        showWebView = false
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                        .bold()
                }
                Text("Where to Spot")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, -10)

            WebViewContainer(url: url)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// Updated to use a provided CLLocation instead of requesting again
func fetchNearestAirportsFromCSV(limit: Int, using userLocation: CLLocation, completion: @escaping ([AirportOption]) -> Void) {
    guard let path = Bundle.main.path(forResource: "icao_airports", ofType: "csv"),
          let data = try? String(contentsOfFile: path) else {
        print("Failed to load CSV file.")
        completion([])
        return
    }

    let rows = data.components(separatedBy: "\n").dropFirst()
    var airportsWithDistance: [(AirportOption, CLLocationDistance)] = []

    for row in rows {
        let columns = row.components(separatedBy: ",")
        if columns.count < 14 { continue }

        let type = columns[2].replacingOccurrences(of: "\"", with: "")
        let ident = columns[1].replacingOccurrences(of: "\"", with: "")
        let name = columns[3].replacingOccurrences(of: "\"", with: "")
        let latStr = columns[4].replacingOccurrences(of: "\"", with: "")
        let lonStr = columns[5].replacingOccurrences(of: "\"", with: "")

        guard type == "large_airport",
              let lat = Double(latStr),
              let lon = Double(lonStr) else { continue }

        let airportLocation = CLLocation(latitude: lat, longitude: lon)
        let distance = userLocation.distance(from: airportLocation)
        let option = AirportOption(icao: ident, name: name)
        airportsWithDistance.append((option, distance))
    }

    let nearest = airportsWithDistance.sorted(by: { $0.1 < $1.1 }).prefix(limit).map { $0.0 }
    completion(nearest)
}

#Preview {
    SearchView().environmentObject(FlightFetcher(userSettings: UserSettings()))
}
