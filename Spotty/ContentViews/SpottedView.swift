//
//  SpottedView.swift
//  Spotty
//
//  Created by Kush Dalal on 10/15/24.
//

import SwiftUI
import MapKit
import BottomSheet
import Charts
import UniformTypeIdentifiers
import UIKit

@available(iOS 17.0, *)
struct SpottedView: View {
    var body: some View {
        MapView()
    }
}

@available(iOS 17.0, *)
struct MapView: View {
    @EnvironmentObject var spottedFlightsStore: SpottedFlightsStore
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.55)
    @State private var offsetY: CGFloat = UIScreen.main.bounds.height // Start off-screen
    @State private var offsetY_2: CGFloat = UIScreen.main.bounds.height // Start off-screen
    
    @State private var showSheet: Bool = true
    @State var searchText: String = ""


    var body: some View {
        GeometryReader { geometry in
            ZStack{
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
                .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
                    .relative(0.25),
                    .relative(0.55),
                    .relativeTop(0.99)
                ], headerContent: {
                    //A SearchBar as headerContent.
                    VStack {
                        HStack{
                            Text("My Spots")
                                .font(.title)
                                .foregroundColor(Color(UIColor.label))
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: {
                                exportCSV(flights: spottedFlightsStore.spottedFlights)
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .bold()
                            }
                            //.buttonStyle(.plain)

                        }
                        .padding(.horizontal, 20)
                        .padding(EdgeInsets(top: -5, leading: 0, bottom: 0, trailing: 0))
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Search", text: self.$searchText)
                        }
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 5)
                        .background(RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.quaternaryLabel)))
                        .padding([.horizontal, .bottom])
                        .onTapGesture {
                            self.bottomSheetPosition = .relativeTop(0.99)
                        }
                    }
                }) {
                    
                    ScrollView{
                        if(spottedFlightsStore.spottedFlights.count == 0) {
                            VStack{
                                Text("No flights spotted yet.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Get out there and spot some planes, then you'll see beautiful charts here!")
                                    .foregroundColor(.secondary)
                                    .font(.callout)
                                    .padding()
                                    .multilineTextAlignment(.center)
                            }
                        }
                        else {
                            VStack{
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(LinearGradient(
                                            gradient: .init(colors: [Color(red: 185 / 255, green: 221 / 255, blue: 237 / 255), Color(red: 211 / 255, green: 198 / 255, blue: 245 / 255)]),
                                            startPoint: .init(x: 0.7, y: 0),
                                            endPoint: .init(x: 0.3, y: 0.6)
                                        ))
                                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.32 , alignment: .bottomLeading)
                                    FlightPieChartView(flights: spottedFlightsStore.spottedFlights)
                                }
                                .offset(y: offsetY)  // Apply the animated offset
                                .onAppear {
                                    // Initialize isChecked based on whether the flight is spotted
                                    withAnimation(.easeIn(duration: 1).delay(0.2)) {
                                        offsetY = 0  // Move it to its final position
                                    }
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(LinearGradient(
                                            gradient: .init(colors: [Color(red: 15 / 255, green: 234 / 255, blue: 88 / 255), Color(red: 45 / 255, green: 217 / 255, blue: 236 / 255)]),
                                            startPoint: .init(x: 0.7, y: 0),
                                            endPoint: .init(x: 0.3, y: 0.6)
                                        ))
                                        .opacity(0.35)
                                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.32 , alignment: .bottomLeading)
                                    AirlineBarChartView(flights: spottedFlightsStore.spottedFlights)
                                }
                                .offset(y: offsetY_2)  // Apply the animated offset
                                .onAppear {
                                    // Initialize isChecked based on whether the flight is spotted
                                    withAnimation(.easeIn(duration: 1).delay(0.4)) {
                                        offsetY_2 = 0  // Move it to its final position
                                    }
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(LinearGradient(
                                            gradient: .init(colors: [Color(red: 242 / 255, green: 156 / 255, blue: 70 / 255), Color(red: 218 / 255, green: 224 / 255, blue: 136 / 255)]),
                                            startPoint: .init(x: 0.4, y: 0.8),
                                            endPoint: .init(x: 0, y: 0.2)
                                        ))
                                        .opacity(0.35)
                                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.15 , alignment: .bottomLeading)
                                    ICAOProgressView(flights: spottedFlightsStore.spottedFlights)
                                }
                                .offset(y: offsetY_2)  // Apply the animated offset
                                .onAppear {
                                    // Initialize isChecked based on whether the flight is spotted
                                    withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                                        offsetY_2 = 0  // Move it to its final position
                                    }
                                }
                                //SpottedFlightsView()
                            }
                        }
                    }
                    
                    
                }
                .customBackground {
                    Color.white
                        .clipShape(
                            .rect(
                                topLeadingRadius: 30,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 30
                            )
                        )
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }
}

@available(iOS 17.0, *)
struct FlightPieChartView: View {
    let flights: [Flight]

    @State private var selectedCount: Int?
    @State private var selectedAircraft: String?

    // Compute the top 5 icaoTypes and group the rest as "Other"
    var flightCounts: [(icaoType: String, count: Int)] {
        let counts = Dictionary(grouping: flights, by: { $0.icaoType ?? "Unknown" })
            .mapValues { $0.count }
            .sorted {
                // First, sort alphabetically by icaoType
                if $0.value == $1.value {
                    return $0.key < $1.key  // Sort ties alphabetically
                }
                return $0.value > $1.value // Sort by count descending
            }
        
        let top5 = counts.prefix(5) // Get top 5
        
        let result = top5.map { ($0.key, $0.value) }

        return result
    }


    var body: some View {
        VStack {
            Chart(flightCounts, id: \.icaoType) { data in
                SectorMark(
                    angle: .value("Count", data.count),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Type", data.icaoType))
                .cornerRadius(5)
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry[chartProxy.plotAreaFrame]
                    VStack {
                        Text("Most Common\nAircraft") // Display the count of the selected aircraft
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text(selectedAircraft ?? flightCounts.first!.icaoType)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            .chartLegend(alignment: .center, spacing: 16)
            
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    }
}

@available(iOS 17.0, *)
struct AirlineBarChartView: View {
    let flights: [Flight]

    // Compute the top 5 airlines based on OperatorFlagCode
    var airlineCounts: [(operatorFlagCode: String, count: Int)] {
        let counts = Dictionary(grouping: flights, by: { $0.OperatorFlagCode ?? "Unknown" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value } // Sort by count descending
        
        let top5 = counts.prefix(5) // Get top 5

        return top5.map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack {
            Text("Top 5 Airlines")
                .font(.title)
                .bold()
                .padding(EdgeInsets(top: 20, leading: 40, bottom: 0, trailing: 40))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Horizontal bar chart
            Chart(airlineCounts, id: \.operatorFlagCode) { data in
                BarMark(
                    x: .value("Count", data.count),
                    y: .value("Airline", data.operatorFlagCode) // Swap x and y
                )
                .foregroundStyle(by: .value("Airline", data.operatorFlagCode))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                // Display the count at the top of each bar
                .annotation(position: .trailing) {
                    Text("\(data.count)")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(.leading, 5)
                }
                .annotation(position: .leading){
                    Image("\(data.operatorFlagCode)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
            }
            .chartXAxis(.hidden) // Hides the Y axis and grid lines
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 10, trailing: 40))
        }
    }
}

struct ICAOProgressView: View {
    let flights: [Flight]
    let totalICAOTypes = 274
    
    var uniqueICAOTypesCount: Int {
        Set(flights.compactMap { $0.icaoType }).count
    }
    
    var progress: Double {
        Double(uniqueICAOTypesCount) / Double(totalICAOTypes)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(uniqueICAOTypesCount) / \(totalICAOTypes) Planes Discovered")
                .font(.title3)
                .bold()
                .padding(.bottom, 5)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 20)
                        .foregroundColor(Color(.systemGray4))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geometry.size.width * progress, height: 20)
                        .foregroundColor(.blue)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("\(Int(progress * 100))% Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            }
        }
        .padding(EdgeInsets(top: 0, leading: 40, bottom: 10, trailing: 40))
    }
}


//-----------------------CSV Stuff--------------------------//


func generateCSV(from flights: [Flight]) -> String {
    var csvString = "ID,CallSign,Registration,Type,ICAO_Type,Origin,Destination,Operator_Flag_Code,Latitude,Longitude,Date_Spotted,Time\n"

    for flight in flights {
        let latitude = flight.position?.latitude.map { "\($0)" } ?? "" // Empty string if nil
        let longitude = flight.position?.longitude.map { "\($0)" } ?? ""
        let operatorFlagCode = flight.OperatorFlagCode ?? "" // Handle nil case


        let row = [
            flight.id ?? "",
            flight.callSign ?? "",
            flight.registration ?? "",
            flight.type ?? "",
            flight.icaoType ?? "",
            flight.origin?.name ?? "",
            flight.destination?.name ?? "",
            operatorFlagCode,
            latitude,
            longitude,
            flight.formattedDate
        ].joined(separator: ",")

        csvString.append("\(row)\n")
    }

    return csvString
}


func saveCSVToDocuments(csvString: String) -> URL? {
    let fileName = "SpottedFlights.csv"
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    
    do {
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    } catch {
        print("Error saving file: \(error)")
        return nil
    }
}



func exportCSV(flights: [Flight]) {
    let csvString = generateCSV(from: flights)
    
    if let fileURL = saveCSVToDocuments(csvString: csvString) {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL])
        picker.modalPresentationStyle = .fullScreen
        
        if let topVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController {
            topVC.present(picker, animated: true)
        }
    }
}



@available(iOS 17.0, *)
#Preview {
    ContentView()
}
