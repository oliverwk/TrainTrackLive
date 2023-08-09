//
//  DepartureBoardTrack.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 05/08/2023.
//

import ActivityKit
import SwiftUI
import os

// Hier een vertrek en aankomst bord laten zien in een list
// en dan een functie toevoegen dat je die kan tracken met een live-activity

// het id van berugen is 8509197

struct DepartureBoardTrack: View {
    @State private var buttonColour: Color = .accentColor
    @State private var stationNaam = "Bergün"
    @ObservedObject var trainDepartures = TrainDepartures(id: 8509197)
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "DepartureBoardTrack"
    )
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(0...(trainDepartures.departures.count-1), id: \.self) { i in
                        Section(trainDepartures.departures[i].stop.station.name!) {
                            HStack {
                                Text("\(trainDepartures.departures[i].stop.departureDate.formatted(date: .omitted, time: .shortened)) --> \(trainDepartures.departures[i].to)")
                                Spacer()
                                Button {
                                    buttonColour = .green
                                    Task { await GoUpdate(i) }
                                    buttonColour = .accentColor
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(buttonColour)
                                        
                                }
                                
                                Button("GO LIVE") {
                                    Task {
                                        await GoLive(i)
                                        await GoUpdate(i)
                                    }
                                }.buttonStyle(.borderedProminent)
                                Button("Notify") {
                                    Notify(i)
                                }.buttonStyle(.bordered)
                            }
                        }
                    }
                }.listStyle(.insetGrouped).listSectionSeparatorTint(.green)
            }
        }
        .searchable(text: $stationNaam)
        .searchScopes($trainDepartures.stationSelected) {
            ForEach(trainDepartures.stationsFound) { scope in
                Text((scope.name ?? scope.id)!)
                    .tag(scope)
            }
        }
        .onChange(of: trainDepartures.stationSelected) { scope in
            logger.log("Getting new departures from serach field met onChange, met naam: \(scope.name ?? "Geen naam") met id: \(scope.id ?? "geen id")")
            Task {
                await trainDepartures.getDepartures(stationId: Int(scope.id ?? "8509197") ?? 8509197)
                self.stationNaam = scope.name ?? scope.id!
            }
        }
        .onSubmit(of: .search, {
            Task {
                if Int(stationNaam) != nil {
                    await trainDepartures.getDepartures(stationId: Int(stationNaam)!)
                } else {
                    await trainDepartures.getStations(stations: stationNaam)
                }
            }
        })
        .navigationBarTitle("Departures", displayMode: .large)
    }
}






class TrainDepartures: ObservableObject {
    @Published var departures = [Stationboard]()
    @Published var actis = [Activity<TrainTrackWidgetAttributes>?]()
    @Published var stationsFound = [TrainStation]()
    @Published var stationSelected = TrainStation(berguen: true)
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "TrainDepartures"
    )
    
    init(id: Int) {
        Task {
            if UserDefaults.standard.string(forKey: "station_id") != nil {
                if Int(UserDefaults.standard.string(forKey: "station_id")!) == id {
                    // De instellingen en textbox zijn het zelfde
                    await self.getDepartures(stationId: id)
                } else if Int(UserDefaults.standard.string(forKey: "station_id")!) == 8509197 {
                    // Het is berguen
                    await self.getDepartures(stationId: 8509197)
                } else {
                    // Er is in de intstellingen een ander station ingevuld
                    self.logger.log("Er is in de intstellingen een ander station ingevuld \(UserDefaults.standard.string(forKey: "station_id")!, privacy: .public)")
                    await self.getDepartures(stationId: Int(UserDefaults.standard.string(forKey: "station_id")!) ?? 8509197)
                }
            } else {
                await self.getDepartures(stationId: id)
            }
        }
    }
    
    func getStations(stations: String) async {
        logger.log("Getting stations for \"\(stations, privacy: .public)\"")
        let stationURL = URL(string: "https://transport.opendata.ch/v1/locations?query=\(stations)")!
        
        var (ds, responseTrain) = (Data(), URLResponse())
        
        do {
            (ds, responseTrain) = try await URLSession.shared.data(from: stationURL)
            let decodedLists = try JSONDecoder().decode(TrainStations.self, from: ds)
            self.logger.log("The response of the train stations is good")
            
            let filteredStations = decodedLists.stations.filter { station in
                return station.icon == "train"
            }
            
            DispatchQueue.main.async {
                self.stationsFound = filteredStations
            }
        } catch {
            if let response = responseTrain as? HTTPURLResponse {
                self.logger.fault("[ERROR] Er was een probleem met het laden een url: \(stationURL.absoluteString, privacy: .public) en met response: \(response, privacy: .public) Met de error: \(String(describing: error), privacy: .public) met data: \n \(String(decoding: ds, as: UTF8.self), privacy: .public)")
                
            } else {
                self.logger.fault("[ERROR] Er was een terwijl de json werd geparsed: \(stationURL.absoluteString, privacy: .public) met data \(String(decoding: ds, as: UTF8.self), privacy: .public) Met de error: \(String(describing: error), privacy: .public)")
                
            }
        }
        // self.stationsFound = [TrainStation(id: "8509197", name: "Berguen", score: nil, coordinate: Coordinate(type: .wgs84, x: 46.603, y: 9.473), distance: nil)]
    }
    
    
    func getDepartures(stationId: Int) async {
        logger.log("Getting departures from \(stationId, privacy: .public)")
        let stationURL = URL(string: "https://transport.opendata.ch/v1/stationboard?id=\(stationId)&limit=10")!
        
        var (d, responseTrain) = (Data(), URLResponse())
        
        do {
            (d, responseTrain) = try await URLSession.shared.data(from: stationURL)
            let ds = String(data: d, encoding: .utf8)?.replacingOccurrences(of: "\\u00fc\\", with: "u")
            let decodedLists = try JSONDecoder().decode(TrainDepartureBoard.self, from: Data(ds!.utf8))
            self.logger.log("The response of the trains is good")
            DispatchQueue.main.async {
                self.departures = decodedLists.stationboard
                for _ in 0...decodedLists.stationboard.count {
                    self.actis.append(nil)
                }
            }
        } catch {
            if let response = responseTrain as? HTTPURLResponse {
                self.logger.fault("[ERROR] Er was een probleem met het laden een url: \(stationURL.absoluteString, privacy: .public) en met response: \(response, privacy: .public) Met de error: \(String(describing: error), privacy: .public) met data: \n \(String(decoding: d, as: UTF8.self), privacy: .public)")
                
            } else {
                self.logger.fault("[ERROR] Er was een terwijl de json werd geparsed: \(stationURL.absoluteString, privacy: .public) met data \(String(decoding: d, as: UTF8.self), privacy: .public) Met de error: \(String(describing: error), privacy: .public)")
                
            }
        }
    }
}

struct DepartureBoardTrack_Previews: PreviewProvider {
    static var previews: some View {
        DepartureBoardTrack()
    }
}
