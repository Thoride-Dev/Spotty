import Foundation
import CoreLocation
import Combine

struct AircraftInfo: Codable {
    let modeS: String
    let manufacturer: String?
    let operatorFlagCode: String?
    let registeredOwners: String?
    let registration: String?
    let type: String?
    let icaoTypeCode: String?

    enum CodingKeys: String, CodingKey {
        case modeS = "ModeS"
        case manufacturer = "Manufacturer"
        case operatorFlagCode = "OperatorFlagCode"
        case registeredOwners = "RegisteredOwners"
        case registration = "Registration"
        case type = "Type"
        case icaoTypeCode = "ICAOTypeCode"
    }
}

struct Flight: Identifiable {
    let id: String // Using icao24 as the unique identifier
    let callSign: String?
    let registration: String?
}

class FlightFetcher: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    private let radiusKm: Double = 30
    private let earthRadiusKm: Double = 6371

    @Published var flights: [Flight] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
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
            guard let data = data, error == nil else {
                print("Network request failed: \(error?.localizedDescription ?? "No error description")")
                return
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let states = jsonResult["states"] as? [[Any]] {
                    states.forEach { state in
                        guard let icao24 = state[0] as? String,
                              let callSign = state[1] as? String else { return }

                        self?.fetchAircraftInfo(hex: icao24) { aircraftInfoOptional in
                            // Ensure aircraftInfo is not nil before proceeding
                            guard let aircraftInfo = aircraftInfoOptional else { return }
                            
                            // Now that aircraftInfo is unwrapped, check for relevant information
                            let hasRelevantInfo = aircraftInfo.manufacturer != nil ||
                                                  aircraftInfo.operatorFlagCode != nil ||
                                                  aircraftInfo.registeredOwners != nil ||
                                                  aircraftInfo.registration != nil ||
                                                  aircraftInfo.type != nil ||
                                                  aircraftInfo.icaoTypeCode != nil

                            if hasRelevantInfo {
                                DispatchQueue.main.async {
                                    // Use the unwrapped aircraftInfo to append a new Flight
                                    self?.flights.append(Flight(id: aircraftInfo.modeS, callSign: callSign, registration: aircraftInfo.registration))
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        task.resume()
    }


    private func fetchAircraftInfo(hex: String, completion: @escaping (AircraftInfo?) -> Void) {
        guard let url = URL(string: "https://hexdb.io/api/v1/aircraft/\(hex)") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching aircraft info: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)  // Notify the caller that the fetch failed.
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let aircraftInfo = try decoder.decode(AircraftInfo.self, from: data)
                // Assuming 'modeS' is mandatory, check if it's present and not empty.
                guard !aircraftInfo.modeS.isEmpty else {
                    print("Aircraft info missing essential 'ModeS' data; skipping.")
                    completion(nil)  // Essential info is missing, so don't proceed with this aircraft.
                    return
                }
                completion(aircraftInfo)  // Successfully decoded and contains essential info.
            } catch {
                print("Error decoding aircraft info: \(error)")
                completion(nil)  // There was a problem decoding, so don't proceed with this aircraft.
            }
        }
        task.resume()
    }

}
