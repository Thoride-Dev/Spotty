//
//  GridCardView.swift
//  Spotty
//
//  Created by Kush Dalal on 6/16/25.
//


import SwiftUI

@available(iOS 26.0, *)
struct GridCardView: View {
    let flight: Flight
    let loadedImage: Image?
    @Environment(\.colorScheme) var colorScheme

    @State private var isShowingDetails = false

    var body: some View {
        Button {
            isShowingDetails = true
        } label: {
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    (loadedImage ?? Image(systemName: "photo"))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)

                    GeometryReader { geometry in
                        let maxSize = min(geometry.size.width, geometry.size.height) * 0.15
                        let fontSize = min(maxSize, 10.5)

                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(radius: 5)
                            .overlay(
                                Text(flight.registration ?? "N/A")
                                    .font(.system(size: fontSize, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            )
                            .frame(
                                width: geometry.size.width * 0.40,
                                height: geometry.size.height * 0.2,
                                alignment: .bottomLeading
                            )
                            .padding(EdgeInsets(top: 63, leading: 7, bottom: 0, trailing: 0))
                    }
                }
            }
        }
        .buttonStyle(PressableCardStyle()) // custom darken effect
        .sheet(isPresented: $isShowingDetails) {
            FlightDetailSheet(flight: flight, loadedImage: loadedImage)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled)
        }
    }
}

// 👇 Custom button style
struct PressableCardStyle: ButtonStyle {
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.4 : 0))
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
