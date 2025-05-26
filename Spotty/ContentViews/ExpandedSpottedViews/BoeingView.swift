//
//  BoeingView.swift
//  Spotty
//
//  Created by Kush Dalal on 2/17/25.
//

import SwiftUI
import Charts

@available(iOS 18.0, *)
struct BoeingView: View {
    let boeingSpottedCount: Int
    let totalBoeingCount: Int
    
    var body: some View {
        LazyVStack(alignment: .leading){
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
                    .frame(width: 200, height: 40)
                    .shadow(radius: 2)
                Text("Boeing Stats")
                    .font(.title2)
            }.padding()
            
            var data: [(name: String, value: Int)] {
                [
                    ("Spotted", boeingSpottedCount),
                    ("Remaining", totalBoeingCount - boeingSpottedCount)
                ]
            }
            
            HStack(alignment: .center) {
                Chart(data, id: \.name) { name, value in
                    SectorMark(
                        angle: .value("Count", value),
                        innerRadius: .ratio(0.618),
                        outerRadius: .ratio(1.0),
                        angularInset: 1
                    )
                    .cornerRadius(4)
                    .foregroundStyle(name == "Spotted" ? Color.teal : Color.gray.opacity(0.3))
                }
                .frame(width: 150, height: 150) // Adjust width as needed
                .padding(.leading) // Optional for spacing
                
                Spacer() // Pushes content to the left
            }
        }
    }
}

