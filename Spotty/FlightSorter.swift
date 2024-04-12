//
//  FlightSorter.swift
//  Spotty
//
//  Created by Kush Dalal on 4/11/24.
//

import CoreLocation

class FlightSorter {
    static func addFlightToList(_ flight: Flight, to flights: inout [Flight]) {
        guard let userLocation = getLocation() else {
            // Handle case where user location could not be obtained
            return
        }

        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let flightCLLocation = CLLocation(latitude: CLLocationDegrees(flight.position?.latitude ?? 0), longitude: CLLocationDegrees(flight.position?.longitude ?? 0))
        let distance = flightCLLocation.distance(from: userCLLocation)

        var insertionIndex = 0
        for (index, existingFlight) in flights.enumerated() {
            let existingFlightCLLocation = CLLocation(latitude: CLLocationDegrees(existingFlight.position?.latitude ?? 0), longitude: CLLocationDegrees(existingFlight.position?.longitude ?? 0))
            let existingFlightDistance = existingFlightCLLocation.distance(from: userCLLocation)
            if distance < existingFlightDistance {
                insertionIndex = index
                break
            }
            insertionIndex = index + 1
        }

        flights.insert(flight, at: insertionIndex)
    }

    private static func getLocation() -> CLLocationCoordinate2D? {
        let locationManager = CLLocationManager()


        let authorizationStatus = locationManager.authorizationStatus
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            // Handle case where app is not authorized to use location services
            print("App is not authorized to use location services.")
            return nil
        }

        guard let location = locationManager.location else {
            // Handle case where user location could not be obtained
            return nil
        }

        return location.coordinate
    }
}

