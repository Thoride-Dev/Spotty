//
//  FlightSearch.swift
//  Spotty
//
//  Created by Kush Dalal on 4/12/24.
//

import Foundation
import UIKit

class FlightSearch: ObservableObject {
    
    func searchFlight(hexOrReg: String, completion: @escaping (Flight?) -> Void) {
        // Check if input is hex or registration
        let isHex = hexOrReg.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789ABCDEF").inverted) == nil
        
        if isHex {
            fetchFlightData(hexCode: hexOrReg, completion: completion)
        } else {
            // Make a call to 'https://hexdb.io/reg-hex?reg=<REG>' to get hex code
            let hexURLString = "https://hexdb.io/reg-hex?reg=\(hexOrReg)"
            guard let hexURL = URL(string: hexURLString) else {
                completion(nil)
                return
            }
            
            let hexTask = URLSession.shared.dataTask(with: hexURL) { data, response, error in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                
                if let hexCode = String(data: data, encoding: .utf8) {
                    if hexCode == "n/a"{
                        completion(nil)
                    } else {
                        self.fetchFlightData(hexCode: hexCode, completion: completion)
                    }
                } else {
                    completion(nil)
                }
            }
            
            hexTask.resume()
        }
    }
    
    private func fetchFlightData(hexCode: String, completion: @escaping (Flight?) -> Void) {
                    
        let callSign = hexCode
        let current_pos = Position(longitude: 0.0, latitude: 0.0)
        let flightFetcher = FlightFetcher(userSettings: UserSettings())
        flightFetcher.fetchAircraftInfo(hex: hexCode) { aircraftInfoOptional in
            guard let aircraftInfo = aircraftInfoOptional else { return }
            
            let hasRelevantInfo = aircraftInfo.manufacturer != nil ||
            aircraftInfo.registeredOwners != nil ||
            aircraftInfo.registration != nil ||
            aircraftInfo.type != nil ||
            aircraftInfo.icaoTypeCode != nil
            print("\(aircraftInfo.modeS)/\(callSign)")
            
            flightFetcher.getRouteInfo(for: callSign) { (origin, destination) in
                DispatchQueue.main.async {
                    guard hasRelevantInfo else { return }
                    
                    var originAirport: Airport?
                    var destinationAirport: Airport?
                    
                    let group = DispatchGroup()
                    
                    if let origin = origin {
                        group.enter()
                        flightFetcher.getAirportInfo(for: origin) { airport in
                            originAirport = airport
                            group.leave()
                        }
                    }
                    
                    if let destination = destination {
                        group.enter()
                        flightFetcher.getAirportInfo(for: destination) { airport in
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
                        flightFetcher.getImageURL(hex: hex) { url in
                            imageURL = url
                            group.leave()
                        }
                    }
                    
                    // Flight not in list, add new flight
                    group.notify(queue: .main) {
                        let cur_flight = Flight(id: aircraftInfo.modeS,
                                                callSign: callSign,
                                                registration: aircraftInfo.registration,
                                                type: aircraftInfo.type,
                                                icaoType: aircraftInfo.icaoTypeCode,
                                                tailNumber: aircraftInfo.registeredOwners,
                                                origin: originAirport,
                                                destination: destinationAirport,
                                                OperatorFlagCode: ofc,
                                                position: current_pos,
                                                imageURL: imageURL,
                                                dateSpotted: Date())
                        
                        
                        completion(cur_flight)
                    }
                }
            }
        }
    }
}
