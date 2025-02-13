//
//  SearchView.swift
//  Spotty
//
//  Created by Kush Dalal on 2/12/25.
//
import SwiftUI
import WebKit

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var flight: Flight? = nil
    @State private var cardId = UUID() // Unique ID for CardView
    @State private var isLoading = false
    @ObservedObject private var flightSearch = FlightSearch()
    @State private var showWebView = false // State to control when to show WebView

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
                            TextField("Search by hex or registration", text: self.$searchText)
                                .onSubmit {
                                    if(self.searchText != ""){
                                        self.searchFlight(self.searchText)
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
                                .id(cardId) // Assign unique ID to CardView
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
                            //.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: geometry.size.width * 0.9,  height: 1)
                            .foregroundColor(Color(.systemGray4))
                        HStack{
                            Button("Where to Spot", systemImage: "location.fill.viewfinder") {
                                showWebView.toggle() // Toggle state to show WebView
                            }
                            .font(.title2)
                            .padding()
                            .buttonStyle(.bordered)
                            
                            Button("Live Atc", systemImage: "waveform.badge.microphone") {
                                if let url = URL(string: "https://www.liveatc.net/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.title2)
                            .padding()
                            .buttonStyle(.bordered)
                        }
                
                    }
                }
                .ignoresSafeArea(.keyboard)
                
                // WebView with slide-in animation
                if showWebView {
                    GeometryReader { geometry in
                        WebView(url: URL(string: "https://www.spotterguide.net/")!, showWebView: $showWebView) // Pass binding to showWebView
                            .frame(width: geometry.size.width, height: geometry.size.height - 3) // Adjust height to leave space for tab bar
                            .transition(.move(edge: .leading)) // Slide-in from the right
                            .zIndex(1) // Ensure it appears on top of other content
                            .onTapGesture {
                                // Optionally, you can close WebView when tapped outside
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
                // Create a new instance of Flight with updated properties
                self.flight = flight
                self.cardId = UUID()
                if flight == nil {
                    self.flight = nil
                    return
                }
                return
            }
        }
    }
}

// WebView struct to embed the web content
struct WebView: View {
    let url: URL
    @Binding var showWebView: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    // Close WebView and return to the Search View
                    withAnimation {
                        showWebView = false
                    }
                }) {
                    Image(systemName: "chevron.left") // Back button
                        .foregroundColor(.blue)
                        .padding()
                        .bold()
                }
                Text("Where to Spot") // Custom title for WebView
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: -10, trailing: 0))
            
            WebViewContainer(url: url) // Custom WebView container
                .edgesIgnoringSafeArea(.all)
        }
        
    }
}

// WebView container that wraps WKWebView
struct WebViewContainer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url)) // Load the URL in WebView
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // You can update the WebView here if necessary
    }
}

#Preview {
    SearchView()
}
