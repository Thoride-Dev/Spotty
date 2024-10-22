//
//  SpottedView.swift
//  Spotty
//
//  Created by Kush Dalal on 10/15/24.
//

import SwiftUI
import MapKit
import BottomSheet

@available(iOS 17.0, *)
struct SpottedView: View {
    var body: some View {
        MapView()
    }
}

@available(iOS 17.0, *)
struct MapView: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.5)
    @State private var showSheet: Bool = true
    @State var searchText: String = ""


    var body: some View {
        ZStack{
            Map(position: .constant(.automatic)){
                ForEach(spottedFlightsStore.spottedFlights) { flight in
                    if(flight.position?.latitude != 0 && flight.position?.longitude != 0){
                        Marker(flight.callSign!, systemImage: "airplane", coordinate: CLLocationCoordinate2D(latitude: (flight.position?.latitude)!, longitude: (flight.position?.longitude)!)).tint(Color(red: 0.25490196, green: 0.67450980, blue: 0.89019607))
                    }
                }
                UserAnnotation()
                
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapPitchToggle()
            }
            .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                .relative(0.200),
                .relative(0.5),
                .relativeTop(0.975)
            ], headerContent: {
                //A SearchBar as headerContent.
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: self.$searchText)
                }
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.vertical, 8)
                .padding(.horizontal, 5)
                .background(RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.quaternaryLabel)))
                .padding([.horizontal, .bottom])
                .onTapGesture {
                    self.bottomSheetPosition = .relativeTop(0.975)
                }
            }) {
                ZStack{
                    SpottedFlightsView()
                }
            }
            .customBackground {
                Color.white
                    .clipShape(
                        .rect(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 30
                        )
                    )
            }
        }
            
    }
}


@available(iOS 17.0, *)
#Preview {
    ContentView()
}
