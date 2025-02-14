//
//  IcaoCompletionView.swift
//  Spotty
//
//  Created by Kush Dalal on 2/13/25.
//
import SwiftUI

struct Aircraft: Identifiable, Codable {
    var id: String { ICAO_Code }  // Use ICAO_Code as unique ID
    let ICAO_Code: String
    let Alternative_Code: String
    let Aircraft_Name: String

    private enum CodingKeys: String, CodingKey {
        case ICAO_Code
        case Alternative_Code
        case Aircraft_Name
    }

    // Custom decoding to handle both numbers and strings for `Alternative_Code`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ICAO_Code = try container.decode(String.self, forKey: .ICAO_Code)
        Aircraft_Name = try container.decode(String.self, forKey: .Aircraft_Name)

        // Decode Alternative_Code as either a String or a Number
        if let altCodeString = try? container.decode(String.self, forKey: .Alternative_Code) {
            Alternative_Code = altCodeString
        } else if let altCodeNumber = try? container.decode(Int.self, forKey: .Alternative_Code) {
            Alternative_Code = String(altCodeNumber)  // Convert number to string
        } else {
            Alternative_Code = ""  // Default value if missing or unrecognized
        }
    }
}


struct IcaoCompletionView: View {
    let flights: [Flight]
    @Environment(\.dismiss) var dismiss  // Allows dismissing the full-screen cover
    @State private var aircraftList: [Aircraft] = []

    var body: some View {
        ZStack{
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(
                        gradient: .init(colors: [Color(red: 242 / 255, green: 156 / 255, blue: 70 / 255), Color(red: 218 / 255, green: 224 / 255, blue: 136 / 255)]),
                        startPoint: .init(x: 0.4, y: 0.8),
                        endPoint: .init(x: 0, y: 0.2)
                    ))
                    .opacity(0.35)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color(UIColor.systemBackground))  // Matches system background

            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()  // Dismiss the view
                    }) {
                        Image(systemName: "xmark")  // Close icon
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .padding(.leading)
                    .buttonStyle(.plain)
                    
                    Spacer()
                    Text("Aircraft Discovery")
                        .font(.subheadline)
                        .bold()
                        .padding(.top, 10)
                    Spacer()
                }
                
                
                
                // Boeing Progress Bar
                VStack(alignment: .leading) {
                    Text("Boeing Aircraft Spotted: \(boeingSpottedCount) / \(totalBoeingCount)")
                        .font(.headline)
                    
                    ProgressView(value: boeingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 10)
                        .padding(.bottom, 10)
                }
                .padding()
                
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                loadAircraftData()  // Load JSON when view appears
            }
        }
    }

    // Function to load JSON file
    func loadAircraftData() {
        if let url = Bundle.main.url(forResource: "IcaoTypes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decodedData = try JSONDecoder().decode([Aircraft].self, from: data)
                aircraftList = decodedData
            } catch {
                print("Error loading JSON: \(error)")
            }
        } else {
            print("JSON file not found")
        }
    }
    
    private var totalBoeingCount: Int {
        aircraftList.filter { $0.Aircraft_Name.contains("Boeing") }.count
    }
    
    private var boeingSpottedCount: Int {
        flights.filter { flight in
            flight.icaoType != nil && aircraftList.contains { $0.ICAO_Code == flight.icaoType && $0.Aircraft_Name.contains("Boeing") }
        }.count
    }
    
    private var boeingProgress: Double {
        totalBoeingCount > 0 ? Double(boeingSpottedCount) / Double(totalBoeingCount) : 0
    }
}
