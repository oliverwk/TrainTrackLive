//
//  DepartureBoardTrackExtended.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 08/08/2023.
//

import SwiftUI
import ActivityKit
import os

extension DepartureBoardTrack {
    func GoLive(_ i: Int) -> Void {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
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
            print("fracs: \(fracs)")
            let initialContentState = TrainTrackWidgetAttributes.ContentState(fracBegin: fracs, CurrentORArrivingStation: currentORArrivingStation?.station.name ?? " ", delay: trainDepartures.departures[i].stop.delay, eindSpoor: "\(trainDepartures.departures[i].passList.last?.platform ?? "Pl. 0")", aankomstTijd: trainDepartures.departures[i].passList.last?.arrivalDate ?? trainDepartures.departures[i].stop.arrivalDate, vertrekTijd: trainDepartures.departures[i].passList.first?.departureDate ?? Date.now, currentTijd: currentORArrivingStation?.arrivalDate ?? Date.now, tijdCurrentSpenderen: ((currentORArrivingStation?.arrivalDate ?? Date.now) - (currentORArrivingStation?.departureDate ?? Date.now)))
            
            let activityAttributes = TrainTrackWidgetAttributes(StartStationName: trainDepartures.departures[i].stop.station.name!, EndStationName: trainDepartures.departures[i].to, TrainName: "\(trainDepartures.departures[i].stationboardOperator) \(trainDepartures.departures[i].category) \(trainDepartures.departures[i].name.replacingOccurrences(of: "0", with: ""))")
            
            let activityContent = ActivityContent(state: initialContentState, staleDate: trainDepartures.departures[i].passList.last?.arrivalDate ?? trainDepartures.departures[i].stop.arrivalDate) // TODO: maak dit een goede datum om te eindgen
            
            do {
                let trainTrackLiveActivity = try Activity.request(attributes: activityAttributes, content: activityContent)
                trainDepartures.actis[i] = trainTrackLiveActivity
                print("Requested a train track Live Activity \(String(describing: trainTrackLiveActivity)).")
            } catch (let error) {
                print("Error requesting train track Live Activity \(error.localizedDescription).")
            }
        }
    }
    
    func Notify(_ i: Int) -> Void
    {
        print("Going to Notify")
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                // Handle the error here.
                print("Er was een error met auth voor notificaties \(String(describing: error))")
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
                
                dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: trainDepartures.departures[i].stop.departureDate)
                
                // Create the trigger as a repeating event.
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents, repeats: false)
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

