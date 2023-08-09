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
    @State private var stationNaam = "Bergün"
    @ObservedObject var trainDepartures = TrainDepartures(id: 8509197)
    
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
                                    // Dit is de reloading knop
                                    var currentORArrivingStation = trainDepartures.departures[i].passList.filter { stop in
                                        if stop.station.name != nil {
                                            if (Date.now.timeIntervalSince1970 > Double(stop.arrivalTimestamp ?? Int(9.0e15))) && (Double(stop.departureTimestamp ?? 0) > Date.now.timeIntervalSince1970) {
                                                // De trein is hier nog niet geweest
                                                return true
                                            } else {
                                                return false
                                            }
                                        } else {
                                            return false
                                        }
                                    }.first
                                    
                                    if currentORArrivingStation == nil {
                                        currentORArrivingStation = trainDepartures.departures[i].passList.filter { stop in
                                            if stop.station.name != nil {
                                                return true
                                            } else {
                                                return false
                                            }
                                        }.first
                                    }
                                    
                                    let tnow = Double(Date.now.timeIntervalSince1970)
                                    let tstart = Double(trainDepartures.departures[i].stop.departureTimestamp!)
                                    let tend = Double(trainDepartures.departures[i].passList.last?.arrivalTimestamp ?? trainDepartures.departures[i].stop.arrivalTimestamp ?? Int(Date.now.timeIntervalSince1970))
                                    let fracs = (tnow - tstart)/(tend - tstart)
                                    print("fracs: \(fracs) from updating")
                                    let updatedTrainStatus = TrainTrackWidgetAttributes.ContentState(fracBegin: fracs, CurrentORArrivingStation: currentORArrivingStation?.station.name ?? "Nergens", delay: trainDepartures.departures[i].stop.delay, eindSpoor: "\(trainDepartures.departures[i].passList.last?.platform ?? "Pl. 0")", aankomstTijd: trainDepartures.departures[i].passList.last?.arrivalDate ?? trainDepartures.departures[i].stop.arrivalDate, vertrekTijd: trainDepartures.departures[i].passList.first?.departureDate ?? Date.now, currentTijd: currentORArrivingStation?.arrivalDate ?? Date.now, tijdCurrentSpenderen: ((currentORArrivingStation?.arrivalDate ?? Date.now) - (currentORArrivingStation?.departureDate ?? Date.now)))
                                    print("deps: \(trainDepartures.departures[i])")
                                    let alertConfiguration: AlertConfiguration?
                                    if Int(Date.now.unix) >= trainDepartures.departures[i].stop.arrivalTimestamp ?? Date.now.unix.int && trainDepartures.departures[i].stop.departureTimestamp ?? Date.now.unix.int <= Int(Date.now.unix) {
                                        alertConfiguration = AlertConfiguration(title: "Trein vertrekt", body: "De trein van \(trainDepartures.departures[i].stop.departureDate.uurMinTekst) vertrekt nu", sound: .default)
                                    } else {
                                        alertConfiguration = nil
                                        
                                    }
                                    
                                    let updatedContent = ActivityContent(state: updatedTrainStatus, staleDate: nil)
                                    
                                    Task {
                                        await trainDepartures.actis[i]?.update(updatedContent, alertConfiguration: alertConfiguration)
                                    }
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                                
                                Button("GO LIVE") {
                                    GoLive(i)
                                }.buttonStyle(.borderedProminent)
                                /*Button("Notify") {
                                    Notify(i)
                                }.buttonStyle(.borderedProminent)*/
                            }
                        }
                    }
                }.listStyle(.insetGrouped).listSectionSeparatorTint(.green)
            }
        }
        .searchable(text: $stationNaam)
        .searchScopes($trainDepartures.stationSelected) {
            ForEach(trainDepartures.stationsFound) { scope in
                Text(scope.name ?? scope.id)
                    .tag(scope)
            }
        }
        .onChange(of: trainDepartures.stationSelected) { scope in
            print("Getting new departures from serach field met onChange, met naam: \(scope.name ?? "Geen naam") met id: \(scope.id)")
            Task {
//                trainDepartures.departures = []
                await trainDepartures.getDepartures(stationId: Int(scope.id) ?? 8509197)
                self.stationNaam = scope.name ?? scope.id
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
        logger.log("Getting station for \(stations, privacy: .public)")
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
