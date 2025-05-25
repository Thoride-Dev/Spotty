//
//  CardView.swift
//  Spotty
//
//  Created by Kush Dalal on 10/15/24.
//

import SwiftUI

struct CardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    let flight: Flight
    let loadedImage: Image?
    @State private var isChecked: Bool = false
    @State private var offsetY: CGFloat = UIScreen.main.bounds.height // Start off-screen

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
                    if let image = loadedImage {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped() // Clip the image to the frame
                            .cornerRadius(30) // Apply corner radius if desired
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
                        let fontSize = min(maxSize, 13.5) // Adjust font size here

                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(radius: 5)
                            .padding() // Add padding to adjust the card size
                            .overlay(
                                VStack {
                                    // Callsign display
                                    Text(flight.callSign ?? "N/A")
                                        .font(.system(size: fontSize, weight: .bold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .padding()
                                }
                            )
                            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3, alignment: .center)
                    }

                    
                    
                    
                }
                .frame(maxWidth: .infinity)
                
                ZStack(alignment: .bottomLeading){
                    //Logo
                    GeometryReader { geometry in
                        HStack{
                            ZStack {
                                Circle()
                                    .fill(.regularMaterial)
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
                                    .fill(.regularMaterial)
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
        .offset(y: offsetY)  // Apply the animated offset
        .onAppear {
            // Initialize isChecked based on whether the flight is spotted
            self.isChecked = isFlightSpotted
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                offsetY = 0  // Move it to its final position
            }
        }
        .opacity(self.isChecked ? 0.3 : 1.0) // Adjust the opacity value as needed
        .contextMenu {
            Button {
                // Add this item to a list of favorites.
            } label: {
                Label("Open Camera", systemImage: "camera")
            }
            Button {
                // Open camera picker and select photo
            } label: {
                Label("Choose Photo", systemImage: "photo")
            }
            
            if(self.isChecked){
                Button {
                    self.spottedFlightsStore.addFlight(flight)
                    print(flight)
                } label: {
                    Label("Re-add Flight", systemImage: "arrow.counterclockwise")
                }
                
            }
        }
       
    }
}


struct ImageLoaderView: View {
    @State private var isImageLoaded = false // Track if the image has been loaded
    @State private var loadedImage: Image? = nil // Store the loaded image
    let flight: Flight
    let imageURL: URL

    var body: some View {
        VStack {

            if isImageLoaded {
                CardView(flight: flight, loadedImage: loadedImage) // Show CardView once image is fully loaded
            }
        }
        .onAppear {
            // Start loading the image in the background
            loadImageFromURL()
        }
    }

    // Simulate image loading from a URL or some other async source
    func loadImageFromURL() {
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            var uiImage: UIImage?

            if let error = error as? URLError {
                if error.code == .unsupportedURL {
                    print("Unsupported URL (code -1002)")
                } else {
                    print("URLSession error: \(error.code.rawValue) — \(error.localizedDescription)")
                }

                uiImage = UIImage(named: "PLACEHOLDER")
            } else if let data = data,
                      let originalImage = UIImage(data: data),
                      let cgImage = originalImage.cgImage {

                let width = cgImage.width
                let height = cgImage.height
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
                let bytesPerPixel = 4
                let bytesPerRow = bytesPerPixel * width
                let bitsPerComponent = 8

                if let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo.rawValue
                ) {
                    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                    if let convertedCGImage = context.makeImage() {
                        uiImage = UIImage(cgImage: convertedCGImage)
                    }
                }
            } else {
                print("Image data is nil or could not be parsed: \(imageURL.absoluteString)")
                uiImage = UIImage(named: "PLACEHOLDER")
            }

            if let validUIImage = uiImage {
                DispatchQueue.main.async {
                    self.loadedImage = Image(uiImage: validUIImage)
                    self.isImageLoaded = true
                }
            }
        }.resume()
    }



}
