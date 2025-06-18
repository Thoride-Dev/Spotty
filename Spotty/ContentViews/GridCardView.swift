//
//  GridCardView.swift
//  Spotty
//
//  Created by Kush Dalal on 6/16/25.
//


import SwiftUI

struct GridCardView: View {
    let flight: Flight  // Your flight data model
    let loadedImage: Image?  // Loaded plane photo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        (loadedImage ?? Image(systemName: "photo"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120) // Adjust height to your design
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(12)

            // Overlay with flight registration at the bottom
            HStack {
                Text(flight.registration ?? "N/A")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                Spacer()
            }
            .padding([.top, .horizontal], 6)
            .background(Color.black.opacity(0.4))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

