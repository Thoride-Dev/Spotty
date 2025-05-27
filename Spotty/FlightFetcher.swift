import Foundation
import UIKit
import CoreLocation
import Combine

struct AircraftInfo: Codable {
    let modeS: String?
    let manufacturer: String?
    let registeredOwners: String?
    let registration: String?
    let type: String?
    let icaoTypeCode: String?
    let operatorFlagCode: String?

    enum CodingKeys: String, CodingKey {
        case modeS = "ModeS"
        case manufacturer = "Manufacturer"
        case registeredOwners = "RegisteredOwners"
        case registration = "Registration"
        case type = "Type"
        case icaoTypeCode = "ICAOTypeCode"
        case operatorFlagCode = "OperatorFlagCode"
    }
}

struct Flight: Codable, Identifiable {
    let id: String?  // This is the modeS
    let callSign: String?
    let registration: String?
    let type: String?
    let icaoType: String?
    let tailNumber: String?
    let origin: Airport?
    let destination: Airport?
    var OperatorFlagCode: String?
    var position: Position?
    let imageURL: URL?
    var dateSpotted: Date
    
    var userImageData: Data?
    // Computed property to convert `Data` to `UIImage`
    var userImage: UIImage? {
        guard let data = userImageData else { return nil }
        return UIImage(data: data)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Uses the user's preferred date format
        formatter.timeStyle = .short // Uses the user's preferred time format
        return formatter.string(from: dateSpotted)
    }
}

struct Position: Codable {
    let longitude: Double?
    let latitude: Double?
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
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var radiusKm: Double = 40
    private let earthRadiusKm: Double = 6371
    private var userSettings: UserSettings
    @Published var userLocation: CLLocation?
    
    @Published var flights: [Flight] = []
    @Published var lastUpdated: Date?
    
    private var cancellable: AnyCancellable?
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        radiusKm = self.userSettings.radiusKm;
        
        cancellable = UserSettings.shared.$radiusKm.sink { newValue in
            self.handleRadiusChange(newValue)
        }
    }
    
    func handleRadiusChange(_ newRadius: Double) {
        self.radiusKm = newRadius
    }
    
    func checkLocationAuthorization() {
        DispatchQueue.global(qos: .userInitiated).async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.authorizationStatus = self.locationManager.authorizationStatus
                    self.handleAuthorization(self.authorizationStatus)
                }
            } else {
                DispatchQueue.main.async {
                    print("Location services are disabled.")
                }
            }
        }
    }


    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        handleAuthorization(authorizationStatus)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            if userSettings.isDebugModeEnabled {
                print("Location services denied or restricted.")
            }
        @unknown default:
            break
        }
    }

    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func refreshFlights() {
        DispatchQueue.main.async {
            self.flights.removeAll()
            self.seenCallSigns.removeAll()
        }

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            if userSettings.isDebugModeEnabled {
                print("Location services not authorized or restricted.")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        guard let location = locations.last else { return }
        self.userLocation = location
        let distance = radiusKm
        self.fetchFlightData(coordinates: location.coordinate, distance: distance)
    }
    
private func fetchFlightData(coordinates: CLLocationCoordinate2D, distance: Double) {
        // Validate coordinate range and distance
        guard distance > 0,
              coordinates.latitude >= -90, coordinates.latitude <= 90,
              coordinates.longitude >= -180, coordinates.longitude <= 180 else {
            if userSettings.isDebugModeEnabled {
                print("Invalid coordinates or distance: lat=\(coordinates.latitude), lon=\(coordinates.longitude), dist=\(distance)")
            }
            return
        }

        // Construct and validate URL
        let urlString = "https://api.adsb.lol/v2/lat/\(coordinates.latitude)/lon/\(coordinates.longitude)/dist/\(distance)"
        
        guard let url = URL(string: urlString) else {
            if userSettings.isDebugModeEnabled {
                print("Failed to create URL from: \(urlString)")
            }
            return
        }

        if userSettings.isDebugModeEnabled {
            print("Fetching flight data from: \(url)")
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                if self?.userSettings.isDebugModeEnabled == true {
                    print("Network request failed: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }

            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let planes = jsonResult["ac"] as? [[String: Any]] {
                    var localSeenCallSigns = Set<String>()
                    
                    for plane in planes {
                        guard let icao24 = plane["hex"] as? String,
                              let callSignUnwrapped = plane["flight"] as? String else { continue }
                        
                        let current_long = plane["lon"] as? Double
                        let current_lat = plane["lat"] as? Double
                        let callSign = callSignUnwrapped.trimmingCharacters(in: .whitespaces)
                        let current_pos = Position(longitude: current_long, latitude: current_lat)

                        if callSign.isEmpty || callSign.count < 3 || !callSign.contains(where: { $0.isNumber }) { continue }
                        if localSeenCallSigns.contains(callSign) { continue }
                        localSeenCallSigns.insert(callSign)
                        
                        self.fetchAircraftInfo(hex: icao24) { aircraftInfoOptional in
                            guard let aircraftInfo = aircraftInfoOptional else { return }

                            let hasRelevantInfo =
                                aircraftInfo.registration != nil ||
                                aircraftInfo.type != nil

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

                                    var ofc = aircraftInfo.operatorFlagCode
                                    if UIImage(named: aircraftInfo.operatorFlagCode ?? "") == nil {
                                        ofc = "preview-airline"
                                    }

                                    var imageURL: URL?
                                    if let hex = aircraftInfo.modeS {
                                        group.enter()
                                        self.getImageURL(hex: hex) { url in
                                            if let validURL = url {
                                                imageURL = validURL
                                            } else {
                                                imageURL = nil
                                                if self.userSettings.isDebugModeEnabled {
                                                    print("No image found for hex: \(hex) — using placeholder.")
                                                }
                                            }
                                            group.leave()
                                        }
                                    }


                                    group.notify(queue: .main) {
                                        guard let existingFlightIndex = self.flights.firstIndex(where: { $0.id == aircraftInfo.modeS }) else {
                                            let cur_flight = Flight(id: aircraftInfo.modeS,
                                                                    callSign: callSign,
                                                                    registration: aircraftInfo.registration,
                                                                    type: aircraftInfo.type,
                                                                    icaoType: aircraftInfo.icaoTypeCode,
                                                                    tailNumber: aircraftInfo.registration,
                                                                    origin: originAirport,
                                                                    destination: destinationAirport,
                                                                    OperatorFlagCode: ofc,
                                                                    position: current_pos,
                                                                    imageURL: imageURL,
                                                                    dateSpotted: Date())

                                            FlightSorter.addFlightToList(cur_flight, to: &self.flights)
                                            return
                                        }

                                        self.flights[existingFlightIndex].position = current_pos
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

    
    
    
    
    
    public func fetchAircraftInfo(hex: String, completion: @escaping (AircraftInfo?) -> Void) {
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
                            guard routeComponents.count <= 3 && routeComponents.count > 1 else {
                                print("Invalid route format")
                                completion(nil, nil)
                                return
                            }
                            let origin = routeComponents[0]
                            let destination = routeComponents[1]
                            completion(origin, destination)
                        } else {
//                            print("Error parsing routeInfo")
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

    func getImageURL(hex: String, completion: @escaping (URL?) -> Void) {
        let imageLinkURL = URL(string: "https://hexdb.io/hex-image-thumb?hex=\(hex)")!
        
        let task = URLSession.shared.dataTask(with: imageLinkURL) { (data, response, error) in
            guard let data = data else {
                print("Error: No data")
                completion(nil)
                return
            }
            
            guard let imageURLString = String(data: data, encoding: .utf8) else {
                print("Error: Invalid image URL")
                completion(nil)
                return
            }
            
            guard let imageURL = URL(string: imageURLString) else {
                print("Error: Invalid image URL format")
                completion(nil)
                return
            }
            
            completion(imageURL)
        }
        
        task.resume()
    }
    
}
