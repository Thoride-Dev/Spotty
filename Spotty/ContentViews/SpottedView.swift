//
//  SpottedView.swift
//  Spotty
//
//  Created by Kush Dalal on 10/15/24.
//

import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct SpottedView: View {
    var body: some View {
        MapView()
    }
}

@available(iOS 17.0, *)
struct MapView: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    var body: some View {
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
            
    }
}

@available(iOS 17.0, *)
#Preview {
    MapView()
}
