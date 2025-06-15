import Foundation
import UIKit
import CoreLocation
import Combine
import SwiftSoup

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
                    // Location services are disabled.
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
            // Debug: Location services denied or restricted.
            _ = userSettings.isDebugModeEnabled
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
            _ = userSettings.isDebugModeEnabled
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
            _ = userSettings.isDebugModeEnabled
            return
        }

        // Construct and validate URL
    let urlString = "https://api.adsb.lol/v2/lat/\(coordinates.latitude)/lon/\(coordinates.longitude)/dist/\(Int(distance.rounded()))"
        
        guard let url = URL(string: urlString) else {
            _ = userSettings.isDebugModeEnabled
            return
        }

        _ = userSettings.isDebugModeEnabled

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                _ = self?.userSettings.isDebugModeEnabled == true
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


                            self.getRouteInfo(for: callSign) { (origin, destination) in
                                DispatchQueue.main.async {
                                    self.lastUpdated = Date()

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

                                    // Safely resolve operator flag asset name, avoiding empty-string warnings
                                    let rawFlagCode = aircraftInfo.operatorFlagCode ?? ""
                                    let ofc: String
                                    if !rawFlagCode.isEmpty, UIImage(named: rawFlagCode) != nil {
                                        ofc = rawFlagCode
                                    } else {
                                        ofc = "preview-airline"
                                    }

                                    var imageURL: URL?
                                    if let hex = aircraftInfo.modeS {
                                        group.enter()
                                        self.getImageURL(hex: hex) { url in
                                            if let validURL = url {
                                                imageURL = validURL
                                                group.leave()
                                            } else {
                                                // Fallback using registration or callsign if no registration
                                                let lookupKey = aircraftInfo.registration ?? callSign
                                                self.getJetPhotosImageURL(registration: lookupKey) { jetURL in
                                                    imageURL = jetURL
                                                    group.leave()
                                                }
                                            }
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
                _ = self.userSettings.isDebugModeEnabled
            }
        }

        task.resume()
    }

    
    
    
    
    
    public func fetchAircraftInfo(hex: String, completion: @escaping (AircraftInfo?) -> Void) {
        guard let url = URL(string: "https://hexdb.io/api/v1/aircraft/\(hex)") else {
            _ = self.userSettings.isDebugModeEnabled
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                _ = self.userSettings.isDebugModeEnabled
                completion(nil)  // If there's an error, don't proceed with this aircraft.
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let aircraftInfo = try decoder.decode(AircraftInfo.self, from: data)
                completion(aircraftInfo)  // Successfully decoded, all keys are present.
            } catch DecodingError.keyNotFound(_, let context) {
                // If a key is missing, don't proceed with this aircraft.
                _ = self.userSettings.isDebugModeEnabled
                completion(nil)
            } catch {
                _ = self.userSettings.isDebugModeEnabled
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
                    completion(nil, nil)
                    return
                }
                
                if let data = data {
                    do {
                        if let routeInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let route = routeInfo["route"] as? String {
                            let routeComponents = route.components(separatedBy: "-")
                            guard routeComponents.count <= 3 && routeComponents.count > 1 else {
                                completion(nil, nil)
                                return
                            }
                            let origin = routeComponents[0]
                            let destination = routeComponents[1]
                            completion(origin, destination)
                        } else {
                            completion(nil, nil)
                        }
                    } catch {
                        completion(nil, nil)
                    }
                }
            }
            task.resume()
        } else {
            completion(nil, nil)
        }
    }
    
    
    func getAirportInfo(for icao: String, completion: @escaping (Airport?) -> Void) {
        let urlString = "https://hexdb.io/api/v1/airport/icao/\(icao)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
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
                        completion(nil)
                    }
                }
            }
            task.resume()
        } else {
            completion(nil)
        }
    }

    func getImageURL(hex: String, attempt: Int = 0, completion: @escaping (URL?) -> Void) {
        let imageLinkURL = URL(string: "https://hexdb.io/hex-image-thumb?hex=\(hex)")!
        
        let task = URLSession.shared.dataTask(with: imageLinkURL) { (data, response, error) in
            // Retry for 500 errors up to 1 time
            if let http = response as? HTTPURLResponse, http.statusCode == 500, attempt < 1 {
                self.getImageURL(hex: hex, attempt: attempt + 1, completion: completion)
                return
            }
            // Guard against any non-200 HTTP response (other than retries for 500 above)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            guard let imageURLString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            guard let imageURL = URL(string: imageURLString) else {
                completion(nil)
                return
            }
            
            completion(imageURL)
        }
        
        task.resume()
    }
    
// JetPhotos Fallback
    private func getJetPhotosImageURL(registration: String, completion: @escaping (URL?) -> Void) {
        // Construct the JetPhotos search URL
        guard let searchURL = URL(string: "https://www.jetphotos.com/registration/\(registration)") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: searchURL) { data, response, error in
            guard let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            do {
                let document = try SwiftSoup.parse(html)
                // Try selecting the main photo element first
                if let imgElement = try document.select("img.result__photo").first() {
                    var src = try imgElement.attr("src")
                    // Handle protocol-relative URLs
                    if src.hasPrefix("//") {
                        src = "https:" + src
                    }
                    if let jetURL = URL(string: src) {
                        completion(jetURL)
                        return
                    }
                }
                // Fallback to any thumbnail images
                let imgThumbs = try document.select("img.photo_thumb")
                if imgThumbs.isEmpty {
                }
                for imgElement in imgThumbs.array() {
                    let src = imgElement.hasAttr("data-src") ? try imgElement.attr("data-src") : try imgElement.attr("src")
                    // Handle protocol-relative URLs
                    let finalSrc = src.hasPrefix("//") ? "https:" + src : src
                    if let jetURL = URL(string: finalSrc) {
                        completion(jetURL)
                        return
                    } else {
                        return
                    }
                }
                return
            } catch {
                print("getJetPhotosImageURL: parsing error: \(error)")
            }
            completion(nil)
        }.resume()
    }
}
