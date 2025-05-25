//
//  IcaoCompletionView.swift
//  Spotty
//
//  Created by Kush Dalal on 2/13/25.
//
import SwiftUI
import Charts

@available(iOS 17.0, *)
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

@available(iOS 18.0, *)
struct ManufacturerCompletion: Identifiable {
    let manufacturer: String
    let completionPercentage: Double
    let ICAO_Codes: [String]
    var id: String { manufacturer }
}

@available(iOS 18.0, *)
struct IcaoCompletionView: View {
    let flights: [Flight]
    @Environment(\.dismiss) var dismiss  // Allows dismissing the full-screen cover
    @State private var aircraftList: [Aircraft] = []
    @State private var hideChevron = false


    
    var uniqueICAOTypesCount: Int {
        Set(flights.compactMap { $0.icaoType }).count
    }

    @available(iOS 18.0, *)
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

            GeometryReader { geometry in
                ScrollView{
                    LazyVStack {
                        HStack(alignment: .center) {
                            Button(action: {
                                dismiss()  // Dismiss the view
                            }) {
                                Image(systemName: "xmark")  // Close icon
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading)
                            .buttonStyle(.plain)
                            
                            Spacer()
                            Text("Aircraft Discovery")
                                .font(.subheadline)
                                .bold()
                            Spacer(minLength: 135)
                        
                        }
                    
                        
                        //MARK: Simple Completions
                        HStack{
                            VStack(alignment: .leading){
                                Text("Boeing Aircraft")
                                    .font(.subheadline)
                                Text("\(boeingSpottedCount) / \(totalBoeingCount)")
                                    .font(.title)
                                    .bold()
                                ZStack{
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.regularMaterial)
                                        .frame(width: 82, height: 20)
                                        .shadow(radius: 2)
                                    
                                    Text("\(Int(boeingProgress * 100))% Spotted")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading){
                                Text("Airbus Aircraft")
                                    .font(.subheadline)
                                Text("\(airbusSpottedCount) / \(totalAirbusCount)")
                                    .font(.title)
                                    .bold()
                                ZStack{
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.regularMaterial)
                                        .frame(width: 82, height: 20)
                                        .shadow(radius: 2)
                                    
                                    Text("\(Int(airbusProgress * 100))% Spotted")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading){
                                Text("Regional Aircraft")
                                    .font(.subheadline)
                                Text("\(regionalSpottedCount) / \(totalRegionalCount)")
                                    .font(.title)
                                    .bold()
                                ZStack{
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.regularMaterial)
                                        .frame(width: 82, height: 20)
                                        .shadow(radius: 2)
                                    Text("\(Int(regionalProgress * 100))% Spotted")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 10, leading: 15, bottom: 15, trailing: 15))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: geometry.size.width * 0.9,  height: 1)
                            .foregroundColor(Color(.systemGray4))
                        
                        //MARK: Manufacturer completion
                        Text("\(uniqueICAOTypesCount) / \(aircraftList.count) Aircraft Discovered")
                            .font(.title)
                            .bold()
                            .padding(.leading, 15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Manufacturer Completion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                            ForEach(manufacturerCompletionData) { data in
                                ZStack {
                                    Rectangle()
                                        .fill(Color.teal.opacity(0.2 + data.completionPercentage * 0.8)) // Darker for higher completion
                                        .frame(height: 50)
                                        .cornerRadius(10)
                                    VStack {
                                        Text(data.manufacturer)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 80, alignment: .center)
                                        Text("\(Int(data.completionPercentage * 100))%")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .center)
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 15, bottom: 15, trailing: 15))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: geometry.size.width * 0.9,  height: 1)
                            .foregroundColor(Color(.systemGray4))
                        
                        //MARK: Rarities
                        
                        OneOffsChartView(manufacturerCompletionData: manufacturerCompletionData, flights: flights, aircraftList: aircraftList)
                        
                        //down chevrom image
                    
                        Spacer(minLength: 60)
                        if !hideChevron {
                            GlowingChevron() // Add the chevron animation
                                .padding(.bottom, 20) // Adjust padding as needed
                        } else {
                            Spacer(minLength: 41)
                        }
                    
                        
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: geometry.size.width * 0.9,  height: 1)
                            .foregroundColor(Color(.systemGray4))
                        
                        ForEach(flights) { flight in
                            /*@START_MENU_TOKEN@*/Text(flight.formattedDate)/*@END_MENU_TOKEN@*/
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        loadAircraftData()  // Load JSON when view appears
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    if newPhase == .interacting {
                        withAnimation {
                            hideChevron = true
                        }
                    }
                }
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
    
    
    //MARK: Boeing Logic
    private var totalBoeingCount: Int {
        let uniqueBoeingTypes = Set(
            aircraftList
                .filter { $0.Aircraft_Name.contains("Boeing") }
                .map { $0.ICAO_Code } // Extract only ICAO codes
        )
        return uniqueBoeingTypes.count
    }
    
    private var boeingSpottedCount: Int {
        let uniqueBoeingTypes = Set(
            flights.compactMap { flight in
                flight.icaoType != nil && aircraftList.contains {
                    $0.ICAO_Code == flight.icaoType && $0.Aircraft_Name.contains("Boeing")
                } ? flight.icaoType : nil
            }
        )
        return uniqueBoeingTypes.count
    }
    
    private var boeingProgress: Double {
        totalBoeingCount > 0 ? Double(boeingSpottedCount) / Double(totalBoeingCount) : 0
    }
    
    
    //MARK: Airbus Logic
    private var totalAirbusCount: Int {
        let uniqueAirbusTypes = Set(
                aircraftList
                    .filter { $0.Aircraft_Name.contains("Airbus") }
                    .map { $0.ICAO_Code } // Extract only ICAO codes
            )
        return uniqueAirbusTypes.count
    }
    
    private var airbusSpottedCount: Int {
        let uniqueAirbusTypes = Set(
            flights.compactMap { flight in
                flight.icaoType != nil && aircraftList.contains {
                    $0.ICAO_Code == flight.icaoType && $0.Aircraft_Name.contains("Airbus")
                } ? flight.icaoType : nil
            }
        )
        return uniqueAirbusTypes.count
    }
    
    private var airbusProgress: Double {
        totalAirbusCount > 0 ? Double(airbusSpottedCount) / Double(totalAirbusCount) : 0
    }
    
    //MARK: Regional Jet Logic
    private var totalRegionalCount: Int {
        let regionalJetTypes = ["Regional", "Embraer 170", "De Havilland", "CRJ", "Embraer RJ","Embraer 190", "Embraer 195", "Embraer 175" ]

        let uniqueRegionalTypes = Set(
            aircraftList
                .filter { aircraft in
                    regionalJetTypes.contains { keyword in aircraft.Aircraft_Name.contains(keyword) }
                }
                .map { $0.ICAO_Code } // Extract unique ICAO codes
        )
        
        return uniqueRegionalTypes.count
    }
    
    private var regionalSpottedCount: Int {
        let regionalJetTypes = ["Regional", "Embraer 170", "De Havilland", "CRJ", "Embraer RJ","Embraer 190", "Embraer 195", "Embraer 175" ]

        let uniqueRegionalTypes: Set<String> = Set(
            flights.compactMap { flight in
                guard let icaoType = flight.icaoType else { return nil } // Ensure ICAO type exists

                // Check if the aircraft list contains a regional jet with this ICAO code
                let isRegional = aircraftList.contains { aircraft in
                    aircraft.ICAO_Code == icaoType &&
                    regionalJetTypes.contains { keyword in aircraft.Aircraft_Name.contains(keyword) }
                }

                return isRegional ? icaoType : nil // Return ICAO code if it's a regional jet
            }
        )

        return uniqueRegionalTypes.count
    }

    
    private var regionalProgress: Double {
        totalRegionalCount > 0 ? Double(regionalSpottedCount) / Double(totalRegionalCount) : 0
    }
    
    //MARK: All aircraft completion
    private var manufacturerCompletionData: [ManufacturerCompletion] {
        let manufacturers = ["Antonov", "Airbus", "Aerospatiale", "BAe / British Aerospace", "Beechcraft / Hawker", "Boeing", "Lockheed", "Cessna", "Bombardier / Canadair", "Dornier", "Douglas", "De Havilland", "Embraer", "Fokker", "Dassault", "Gulfstream", "Ilyushin", "Learjet", "Avro", "Saab", "Shorts", "Tupolev", "Yakovlev"]

        let manufacturerGroups: [String: String] = [
            "BAe": "BAe / British Aerospace",
            "British Aerospace": "BAe / British Aerospace",
            "Beechcraft": "Beechcraft / Hawker",
            "Hawker": "Beechcraft / Hawker",
            "Bombardier": "Bombardier / Canadair",
            "Canadair": "Bombardier / Canadair"
        ]

        var spottedByManufacturer: [String: Set<String>] = [:]
        var totalByManufacturer: [String: Set<String>] = [:]

        // Initialize all manufacturers
        for manufacturer in manufacturers {
            spottedByManufacturer[manufacturer] = Set()
            totalByManufacturer[manufacturer] = Set()
        }

        // Function to determine the grouped manufacturer
        func getGroupedManufacturer(for aircraft: Aircraft) -> String {
            for (key, group) in manufacturerGroups {
                if aircraft.Aircraft_Name.contains(key) {
                    return group
                }
            }
            return manufacturers.first { aircraft.Aircraft_Name.contains($0) } ?? "One-offs"
        }

        // Count total unique ICAO types per manufacturer
        for aircraft in aircraftList {
            let manufacturer = getGroupedManufacturer(for: aircraft)
            totalByManufacturer[manufacturer, default: Set()].insert(aircraft.ICAO_Code)
        }

        // Count unique ICAO types spotted per manufacturer
        for flight in flights {
            guard let icaoType = flight.icaoType else { continue }
            if let aircraft = aircraftList.first(where: { $0.ICAO_Code == icaoType }) {
                let manufacturer = getGroupedManufacturer(for: aircraft)
                spottedByManufacturer[manufacturer, default: Set()].insert(icaoType)
            }
        }

        // Convert to ManufacturerCompletion
        return totalByManufacturer.map { manufacturer, totalSet in
            let spottedSet = spottedByManufacturer[manufacturer] ?? Set()
            let completion = totalSet.isEmpty ? 0.0 : (Double(spottedSet.count) / Double(totalSet.count))
            
            return ManufacturerCompletion(
                manufacturer: manufacturer,
                completionPercentage: completion,
                ICAO_Codes: Array(totalSet).sorted() // Convert set to sorted array
            )
        }.sorted { $0.completionPercentage > $1.completionPercentage } // Sort by completion %
    }

    
    //MARK: One-offs

    struct OneOffsChartView: View {
        let manufacturerCompletionData: [ManufacturerCompletion]
        let flights: [Flight]
        let aircraftList: [Aircraft]  // Add aircraft list to map ICAO codes to full names

        @State private var selectedICAO: String?  // Track the selected ICAO code
        
        private var oneOffsData: [(icaoCode: String, spotted: Bool)] {
            guard let oneOffs = manufacturerCompletionData.first(where: { $0.manufacturer == "One-offs" }) else {
                return []
            }
            
            let spottedICAOs = Set(flights.compactMap { $0.icaoType }) // Extract all spotted ICAOs
            
            return oneOffs.ICAO_Codes.map { icao in
                (icao, spottedICAOs.contains(icao)) // Check if spotted
            }
        }

        private var spottedCount: Int {
            oneOffsData.filter { $0.spotted }.count
        }

        private var totalOneOffs: Int {
            oneOffsData.count
        }

        private func aircraftName(for icao: String) -> String {
            aircraftList.first(where: { $0.ICAO_Code == icao })?.Aircraft_Name ?? "Unknown Aircraft"
        }

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("Rare Aircraft Spotted")
                        .font(.headline)
                    Spacer()
                    Text("\(spottedCount)/\(totalOneOffs)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)

                Chart(oneOffsData, id: \.icaoCode) { data in
                    BarMark(
                        x: .value("ICAO Code", data.icaoCode),
                        stacking: .normalized
                    )
                    .foregroundStyle(
                        selectedICAO == data.icaoCode
                            ? Color.green // Highlight the selected bar with green
                            : (data.spotted ? Color.teal.opacity(0.8) : Color.gray.opacity(0.5)) // Regular color for spotted and unspotted
                    )                }
                .frame(height: 50)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel {
                            if let code = value.as(String.self) { // Extracts the ICAO code
                                Text(code)
                                    .rotationEffect(.degrees(-65))
                                    .fixedSize()
                                    .offset(x: -5, y: 5)
                            }
                        }
                    }
                }
                .chartXSelection(value: $selectedICAO)  // Use chartXSelection to bind selected ICAO
                .padding(.bottom, 10)
                .chartXScale(domain: .automatic)

                // Display selected aircraft name when a bar is tapped
                if let selectedICAO = selectedICAO {
                    Text("\(aircraftName(for: selectedICAO)) (\(selectedICAO))")
                        .font(.subheadline)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .padding()
        }
    }
    
    //MARK: Chevron
    struct GlowingChevron: View {
        @State private var isAnimating = false

        var body: some View {
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 30, weight: .bold)) // Adjust size and weight
                .foregroundColor(.primary) // Change color as needed
                .opacity(isAnimating ? 1.0 : 0.5) // Fading effect
                .scaleEffect(isAnimating ? 1.2 : 1.0) // Subtle scaling effect
                .shadow(color: .teal.opacity(0.8), radius: isAnimating ? 10 : 5) // Glowing effect
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isAnimating.toggle()
                    }
                }
        }
    }


}
