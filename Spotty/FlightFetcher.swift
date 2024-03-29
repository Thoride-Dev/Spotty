import Foundation
import CoreLocation
import Combine

struct AircraftInfo: Codable {
    let modeS: String
    let manufacturer: String?
    let registeredOwners: String?
    let registration: String?
    let type: String?
    let icaoTypeCode: String?

    enum CodingKeys: String, CodingKey {
        case modeS = "ModeS"
        case manufacturer = "Manufacturer"
        case registeredOwners = "RegisteredOwners"
        case registration = "Registration"
        case type = "Type"
        case icaoTypeCode = "ICAOTypeCode"
    }
}

struct Flight: Identifiable {
    let id: String  // This is the modeS
    let callSign: String?
    let registration: String?
    let type: String?
    let tailNumber: String?
}

class FlightFetcher: NSObject, CLLocationManagerDelegate, ObservableObject {
    private var seenCallSigns = Set<String>()
    private let locationManager = CLLocationManager()
    private let radiusKm: Double = 30
    private let earthRadiusKm: Double = 6371
    private var userSettings: UserSettings

    @Published var flights: [Flight] = []
    
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        // Additional setup...
    }
    
    func refreshFlights() {
        DispatchQueue.main.async {
            //Clear existing flights data to reflect the refresh state in the UI.
            self.flights.removeAll()
            self.seenCallSigns.removeAll()
        }

        // compatability issue - checking location auth status lags UI
        
        // Stop previous location updates
//        locationManager.stopUpdatingLocation()

        // Check if location services are enabled and authorized before starting updates
//        if locationManager.authorizationStatus() {
//
//        } else {
//            if self.userSettings.isDebugModeEnabled {
//                print("Location services not enabled")
//            }
//        }
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        calculateBoundingBox(location: location.coordinate)
    }

    private func calculateBoundingBox(location: CLLocationCoordinate2D) {
        let C = 2 * .pi * earthRadiusKm
        let dy = radiusKm * 360 / C
        let dx = dy * cos(location.latitude * .pi / 180)

        let lamin = location.latitude - dy
        let lomin = location.longitude - dx
        let lamax = location.latitude + dy
        let lomax = location.longitude + dx

        fetchFlightData(lamin: lamin, lomin: lomin, lamax: lamax, lomax: lomax)
    }

    private func fetchFlightData(lamin: Double, lomin: Double, lamax: Double, lomax: Double) {
        let urlString = "https://opensky-network.org/api/states/all?lamin=\(lamin)&lomin=\(lomin)&lamax=\(lamax)&lomax=\(lomax)"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                if self!.userSettings.isDebugModeEnabled {
                    print("Network request failed: \(error?.localizedDescription ?? "No error description")")
                }
                return
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let states = jsonResult["states"] as? [[Any]] {
                    var localSeenCallSigns = Set<String>()
                    
                    for state in states {
                        guard let icao24 = state[0] as? String,
                              let callSignUnwrapped = state[1] as? String else { continue }

                        let callSign = callSignUnwrapped.trimmingCharacters(in: .whitespaces)
                        
                        // Filter out call signs that are too short or don't have enough information
                        if callSign.isEmpty || callSign.count < 3 || !callSign.contains(where: { $0.isNumber }) { continue }
                        
                        // Ensure we don't process duplicate call signs
                        if localSeenCallSigns.contains(callSign) { continue }
                        localSeenCallSigns.insert(callSign)

                        self.fetchAircraftInfo(hex: icao24) { aircraftInfoOptional in
                            guard let aircraftInfo = aircraftInfoOptional else { return }
                            
                            let hasRelevantInfo = aircraftInfo.manufacturer != nil ||
                                                  aircraftInfo.registeredOwners != nil ||
                                                  aircraftInfo.registration != nil ||
                                                  aircraftInfo.type != nil ||
                                                  aircraftInfo.icaoTypeCode != nil

                            if hasRelevantInfo {
                                DispatchQueue.main.async {
                                    // Check if the list already contains a flight with the same id (modeS)
                                    if !self.flights.contains(where: { $0.id == aircraftInfo.modeS }) {
                                        self.flights.append(Flight(id: aircraftInfo.modeS,
                                                                    callSign: callSign,
                                                                    registration: aircraftInfo.registration,
                                                                    type: aircraftInfo.type,
                                                                    tailNumber: aircraftInfo.registeredOwners))
                                    }
                                }
                            }

                        }
                    }
                }
            } catch {
                if self.userSettings.isDebugModeEnabled {
                    print("Error decoding JSON: \(error)")
                }
                
            }
        }
        task.resume()
    }





    private func fetchAircraftInfo(hex: String, completion: @escaping (AircraftInfo?) -> Void) {
        guard let url = URL(string: "https://hexdb.io/api/v1/aircraft/\(hex)") else {
            if self.userSettings.isDebugModeEnabled {
                print("Invalid URL")
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                if self.userSettings.isDebugModeEnabled {
                    print("Error fetching aircraft info: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(nil)  // If there's an error, don't proceed with this aircraft.
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let aircraftInfo = try decoder.decode(AircraftInfo.self, from: data)
                completion(aircraftInfo)  // Successfully decoded, all keys are present.
            } catch DecodingError.keyNotFound(_, let context) {
                // If a key is missing, don't proceed with this aircraft.
                if self.userSettings.isDebugModeEnabled {
                    print("Missing key: \(context.debugDescription)")
                }
                completion(nil)
            } catch {
                if self.userSettings.isDebugModeEnabled {
                    print("Error decoding aircraft info: \(error)")
                }
                completion(nil)  // There was a problem decoding, so don't proceed with this aircraft.
            }
        }
        task.resume()
    }


}
