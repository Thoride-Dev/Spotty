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

struct Flight: Codable, Identifiable {
    let id: String  // This is the modeS
    let callSign: String?
    let registration: String?
    let type: String?
    let tailNumber: String?
    let origin: Airport?
    let destination: Airport?
}


struct Airport: Codable {
    var icao = "N/A"
    var iata = "N/A"
    var name = "N/A"
    var country_code = "N/A"
    var latitude = 0.00
    var longitude = 0.00
    var region_name = "N/A"
}

class FlightFetcher: NSObject, CLLocationManagerDelegate, ObservableObject {
    private var seenCallSigns = Set<String>()
    private let locationManager = CLLocationManager()
    private let radiusKm: Double = 30
    private let earthRadiusKm: Double = 6371
    private var userSettings: UserSettings
    
    @Published var flights: [Flight] = []
    @Published var lastUpdated: Date?
    
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func refreshFlights() {
        DispatchQueue.main.async {
            self.flights.removeAll()
            self.seenCallSigns.removeAll()
        }
        
        // Check if location services are enabled and if the app is authorized to use them
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Location services are authorized, start updating location
                startLocationUpdates()
            case .notDetermined:
                // The user has not yet made a choice regarding whether the app can use location services
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // The app is not authorized to use location services
                if userSettings.isDebugModeEnabled {
                    print("Location services not authorized or restricted.")
                }
            @unknown default:
                // Handle any future cases
                break
            }
        } else {
            // Location services are not enabled
            if userSettings.isDebugModeEnabled {
                print("Location services not enabled.")
            }
        }
    }
    
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        self.calculateBoundingBox(location: location.coordinate)
    }
    
    private func calculateBoundingBox(location: CLLocationCoordinate2D) {
        let C = 2 * .pi * earthRadiusKm
        let dy = radiusKm * 360 / C
        let dx = dy * cos(location.latitude * .pi / 180)
        
        let lamin = location.latitude - dy
        let lomin = location.longitude - dx
        let lamax = location.latitude + dy
        let lomax = location.longitude + dx
        
        self.fetchFlightData(lamin: lamin, lomin: lomin, lamax: lamax, lomax: lomax)
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
                            print("\(aircraftInfo.modeS)/\(callSign)")
                            
                            self.getRouteInfo(for: callSign) { (origin, destination) in
                                DispatchQueue.main.async {
                                    self.lastUpdated = Date()
                                    guard hasRelevantInfo else { return }

                                    let flightExists = self.flights.contains { $0.id == aircraftInfo.modeS }
                                    guard !flightExists else { return }

                                    var originAirport: Airport?
                                    var destinationAirport: Airport?

                                    let group = DispatchGroup()

                                    if let origin = origin {
                                        group.enter()
                                        self.getAirportInfo(for: origin) { airport in
                                            originAirport = airport
                                            group.leave()
                                        }
                                    }

                                    if let destination = destination {
                                        group.enter()
                                        self.getAirportInfo(for: destination) { airport in
                                            destinationAirport = airport
                                            group.leave()
                                        }
                                    }

                                    group.notify(queue: .main) {
                                        guard !self.flights.contains(where: { $0.id == aircraftInfo.modeS }) else { return }

                                        self.flights.append(Flight(id: aircraftInfo.modeS,
                                                                   callSign: callSign,
                                                                   registration: aircraftInfo.registration,
                                                                   type: aircraftInfo.type,
                                                                   tailNumber: aircraftInfo.registeredOwners,
                                                                   origin: originAirport,
                                                                   destination: destinationAirport))
                                    }
                                }
                            }


                        }
                    }
                    print(self.flights)
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
    
    func getRouteInfo(for callsign: String, completion: @escaping (String?, String?) -> Void) {
        let urlString = "https://hexdb.io/api/v1/route/icao/\(callsign)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    completion(nil, nil)
                    return
                }
                
                
                if let data = data {
                    do {
                        if let routeInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let route = routeInfo["route"] as? String {
                            let routeComponents = route.components(separatedBy: "-")
                            guard routeComponents.count <= 3 else {
                                print("Invalid route format")
                                completion(nil, nil)
                                return
                            }
                            let origin = routeComponents[0]
                            let destination = routeComponents[1]
                            completion(origin, destination)
                        } else {
                            print("Error parsing routeInfo")
                            completion(nil, nil)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        completion(nil, nil)
                    }
                }
            }
            task.resume()
        } else {
            print("Invalid URL")
            completion(nil, nil)
        }
    }
    
    
    func getAirportInfo(for icao: String, completion: @escaping (Airport?) -> Void) {
        let urlString = "https://hexdb.io/api/v1/airport/icao/\(icao)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error: Invalid response")
                    completion(nil)
                    return
                }
                
                if let data = data {
                    do {
                        if let airportData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            let airportInfo = Airport(icao: airportData["icao"] as? String ?? "N/A",
                                                      iata: airportData["iata"] as? String ?? "N/A",
                                                      name: airportData["airport"] as? String ?? "N/A",
                                                      country_code: airportData["country_code"] as? String ?? "N/A",
                                                      latitude: airportData["latitude"] as? Double ?? 0.00,
                                                      longitude: airportData["longitude"] as? Double ?? 0.00,
                                                      region_name: airportData["region_name"] as? String ?? "N/A")
                            completion(airportInfo)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        completion(nil)
                    }
                }
            }
            task.resume()
        } else {
            print("Invalid URL")
            completion(nil)
        }
    }


    
}
