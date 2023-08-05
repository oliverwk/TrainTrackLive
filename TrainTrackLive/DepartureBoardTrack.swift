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
                                Button("GO LIVE") {
                                    if ActivityAuthorizationInfo().areActivitiesEnabled {
                                        let currentORArrivingStation = trainDepartures.departures[i].passList.filter { stop in
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
                                        }
                                        
                                        let initialContentState = TrainTrackWidgetAttributes.ContentState(frac: 0.8, CurrentORArrivingStation: currentORArrivingStation.first?.station.name ?? "Nergens", delay: trainDepartures.departures[i].stop.delay, eindSpoor: "\(trainDepartures.departures[i].passList.last?.platform ?? "Pl. 0")", aankomstTijd: trainDepartures.departures[i].passList.last?.arrivalDate ?? trainDepartures.departures[i].stop.arrivalDate, vertrekTijd: trainDepartures.departures[i].passList.first?.arrivalDate ?? Date.now, currentTijd: currentORArrivingStation.first?.arrivalDate ?? Date.now, tijdCurrentSpenderen: ((currentORArrivingStation.first?.arrivalDate ?? Date.now) - (currentORArrivingStation.first?.departureDate ?? Date.now)))
                                        
                                        let activityAttributes = TrainTrackWidgetAttributes(StartStationName: trainDepartures.departures[i].stop.station.name!, EndStationName: trainDepartures.departures[i].to, TrainName: "\(trainDepartures.departures[i].stationboardOperator) \(trainDepartures.departures[i].category) \(trainDepartures.departures[i].name.replacingOccurrences(of: "0", with: ""))")
                                        
                                        let activityContent = ActivityContent(state: initialContentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)
                                        
                                        do {
                                            let trainTrackLiveActivity = try Activity.request(attributes: activityAttributes, content: activityContent)
                                            print("Requested a train track Live Activity \(String(describing: trainTrackLiveActivity)).")
                                           } catch (let error) {
                                               print("Error requesting train track Live Activity \(error.localizedDescription).")
                                           }
                                    }
                                }
                                Button("Notify") {
                                    print("Going to Notify")
                                    let center = UNUserNotificationCenter.current()
                                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                        
                                        if let error = error {
                                            // Handle the error here.
                                            print("Er was een error met atuh voor notificaties \(String(describing: error))")
                                        }
                                        
                                        if granted {
                                            
                                            let content = UNMutableNotificationContent()
                                            content.title = "Er is een \(trainDepartures.departures[i].stationboardOperator) \(trainDepartures.departures[i].category) \(trainDepartures.departures[i].name.replacingOccurrences(of: "0", with: ""))"
                                            content.body = "Die vertrek van Bergün om \(trainDepartures.departures[i].stop.arrivalDate.formatted(date: .omitted, time: .standard))"
                                            var dateComponents = DateComponents()
                                            dateComponents.calendar = Calendar.current
                                            
                                           // dateComponents.weekday = 3  // Tuesday
                                            //dateComponents.hour = 14    // 14:00 hours
                                            dateComponents.minute = Calendar.current.component(.minute, from: Date())+1

                                            
                                            // Create the trigger as a repeating event.
                                            let trigger = UNCalendarNotificationTrigger(
                                                dateMatching: dateComponents, repeats: true)
                                            print("versturen om \(dateComponents.debugDescription) \(String(describing: dateComponents.second))")
                                            
                                            // Create the request
                                            let uuidString = UUID().uuidString
                                            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                                            
                                            
                                            // Schedule the request with the system.
                                            let notificationCenter = UNUserNotificationCenter.current()
                                            notificationCenter.add(request) { (error) in
                                                if error != nil {
                                                    // Handle any errors.
                                                    print("er was een error: \(error.debugDescription)")
                                                } else {
                                                    print("notificatie verstuurd")
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                                
                            }
                        }
                    }
                }.listStyle(.insetGrouped).listSectionSeparatorTint(.green)
            }
        }
    }
    
}



class TrainDepartures: ObservableObject {
    @Published var departures = [Stationboard]()
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "TrainDepartures"
    )
    
    init(id: Int) {
        Task {
            await self.getDepartures(stationId: id)
        }
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
            self.departures = decodedLists.stationboard
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
