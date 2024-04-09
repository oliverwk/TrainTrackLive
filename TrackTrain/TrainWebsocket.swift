//
//  TrainWebsocket.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 09/04/2024.
//

import Foundation
import SwiftUI
import MapKit
import os


class TrainWebsocket: ObservableObject {
    @Published var locations = [LocationTrain]()
    var messages = [String]()
    var boundbox = ""
    
    private var webSocketTask: URLSessionWebSocketTask?
    let logger = Logger(
        subsystem: "nl.wittopkoning.tracktrain",
        category: "TrainWebsocket"
    )

    func connect(_ location: MKCoordinateRegion = MKCoordinateRegion(center: coordinate(46.631158, 9.746958), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))) {
        let map_key: String
        if (UserDefaults.standard.string(forKey: "token_map") != nil) {
            self.logger.log("Er was een map token gevonden in settings, die moet worden bewaard in de instellingen app. Dit is hem: \(String(describing: UserDefaults.standard.string(forKey: "token_map")), privacy: .public)")
            map_key = UserDefaults.standard.string(forKey: "token_map") ?? "5cc87b12d7c5370001c1d655babfd9dc82ef43d99b1f12763a1ca6b4"
            UserDefaults.standard.set(UserDefaults.standard.string(forKey: "token_map"), forKey: "token_map")
        } else {
            map_key = "5cc87b12d7c5370001c1d655babfd9dc82ef43d99b1f12763a1ca6b4"
            UserDefaults.standard.set(map_key, forKey: "token_map")
        }
        if ((webSocketTask?.state != nil) && (webSocketTask?.state == .running)) {
         // terminate the websocket
        }
        guard let url = URL(string: "wss://tralis-tracker-api.geops.io/ws?key=\(map_key)") else { return }
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        boundbox = createBoundBox(location)
        // boundbox = "819862.6976440828 5929181.685732176 843405.3023559172 5938736.3142678235"; // Dit is Bern
        // boundbox = "1075401.940808419 5866728.345598243 1095724.427047632 5896720.6813848780"; // Dit is berguen
       
        sendMessage("BBOX \(boundbox) 13 gen=100 mots=subway,rail,ferry,cablecar,gondola,funicular")
        // BBOX <left> <bottom> <right> <top> <zoom>[ tenant=<tenant>][ gen=<generalization>][ mots=<mot1,mot2,...>]
        receiveMessage()
        sendMessage("BUFFER 180 100")
        receiveMessage()
    }
    
    
    func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                self.logger.error("Er was een error met ontvangen van de berichten: \(String(describing: error))")
            case .success(let message):
                switch message {
                case .string(let text):
                    self.messages.append(text)
                    self.logger.log("There was data from the server")
                    
                    do {
                        if text.contains("{\"source\":\"websocket\"") { // Als het een status bericht is dan negeren
                            self.logger.log("Het was een status open bericht")
                            return
                        } else { // Anders kunnen we door met de echte data
                            // Get in the right format and decode json
                            let data = text.data(using: .utf8)!
                            let trainUpdate = try JSONDecoder().decode(TrainUpdate.self, from: data)
                            
                            self.logger.log("TrainUpdate is goed en nu locaties toevoegen")
                            for itemks in trainUpdate.content {
                                if let itemk = itemks {
                                    self.logger.log("\(itemk.content.geometry.coordinates)")
                                    let trainName = " \(itemk.content.properties.tenant.uppercased()) \(itemk.content.properties.type.firstCapitalized) \(itemk.content.properties.line.name)"
                                    let clName = itemk.content.properties.line.color
                                    let TrueColourName = (clName ?? "#0xff0000").dropFirst(2)
                                    let cl = Color(hex: String(TrueColourName))
                                    let containsTrainAlready = self.locations.contains { return $0.id == itemk.content.properties.trainID }
                                    
                                    
                                    if !containsTrainAlready {
                                        DispatchQueue.main.async {
                                           // self.locations.append(LocationTrain(id: itemk.content.properties.trainID, name: trainName, opData: itemk, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals))
                                        }
                                        self.logger.log("Een nieuw location toegevoeg  name:\(trainName, privacy: .public) en locatie: \(itemk.content.geometry.coordinates, privacy: .public)")
                                    } else {
                                        self.logger.log("Het id zit al in de location")
                                    }
                                    
                                    
                                    DispatchQueue.main.async {
                                        self.locations = self.locations.map { location in
                                            if location.id == itemk.content.properties.trainID {
                                                return LocationTrain(id: "RHBRE87667", name: "RHB RE87667", colour: .blue, from: Town(id: "29339230", name: "Bergün", coordinates: [46.631158, 9.746958]), to: Town(id: "29309230", name: "Preda", coordinates: [46.588862, 9.775371]), currentCoordinates: [46.606828, 9.755901], coordinates: [[46.606828, 9.755901]], timeIntervals: [[9,5]])
                                            } else {
                                                return location
                                            }
                                        }
                                    }
                                    
                       
                                }
                            }
                        }
                    } catch {
                        self.logger.log("Er was een error met json van de websocket bericht met error \(String(describing: error), privacy: .public)")
                    }
                    
                    
                case .data(let data):
                    // Handle binary data
                    self.logger.log("De data is binair")
                    self.logger.log("Data: \(data.debugDescription, privacy: .public)")
                    break
                @unknown default:
                    print("HI, no data or error")
                    break
                }
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let _ = message.data(using: .utf8) else { return }
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                self.logger.error("Er was een error met het versturen van een  bericht: \(message, privacy: .public) met de error: \(String(describing: error)), privacy: .public)")
            }
        }
    }
    
    func getStopsTrains(_ id: String) async -> TrainStopContent? {
        let msg = "GET stopsequence_\(id)"
        logger.log("sending msg to the server via websocket: \(msg)")
        
        do {
            try await webSocketTask?.send(.string(msg))
            let messageStop = try await webSocketTask?.receive()
            switch messageStop {
            case let .string(trainStops):
                //                logger.log("Got the data form the stops: \(trainStops.prettyJSON)")
                self.messages.append(trainStops)
                let trainStopss = trainStops.replacingOccurrences(of: ALBULA_TUNNEL_PENDING, with: "").replacingOccurrences(of: ALBULA_TUNNEL_LEAVING, with: "")
                logger.log("Got the data from \(msg)")
                let data = Data(trainStopss.utf8)
                logger.log("data: \(data.debugDescription)")
                let trainStopsJson = try JSONDecoder().decode(TrainStopUpdate.self, from: data)
                return trainStopsJson.content[0]
            case let .data(data):
                logger.log("We got data which isn't expected \(data.debugDescription)")
                return nil
            case .none:
                logger.error("We didn't get any messages")
                return nil
            @unknown default:
                logger.log("unkown message received")
                return nil
            }
        } catch {
            self.logger.error("We got an error with send \(msg) to the weboscket server or with the receiving met error \(String(describing: error))")
            return nil
        }
        
    }
}
