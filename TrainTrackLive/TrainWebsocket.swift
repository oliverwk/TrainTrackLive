//
//  TrainWebsocket.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//

import Foundation
import SwiftUI
import MapKit
import os


class TrainWebsocket: ObservableObject {
    
    @Published var locations = [LocationTrain]()
    var messages = [String]()
    let templ = TrainUpdate(source: "buffer", timestamp: 1608098, clientReference: "", content: [])
    
    private var webSocketTask: URLSessionWebSocketTask?
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "TrainWebsocket"
    )
    
    init() {
        self.connect()
    }
    
    private func connect() {
        let map_key: String
        if (UserDefaults.standard.string(forKey: "token_map") != nil) {
            self.logger.log("Er was een map token gevonden in settings, die moet worden bewaard in de instellingen app. Dit is hem: \(String(describing: UserDefaults.standard.string(forKey: "token_map")), privacy: .public)")
            map_key = UserDefaults.standard.string(forKey: "token_map") ?? "5cc87b12d7c5370001c1d655842890e432df4736b3553feb3c7cd2d6"
            UserDefaults.standard.set(UserDefaults.standard.string(forKey: "token_map"), forKey: "token_map")
        } else {
            map_key = "5cc87b12d7c5370001c1d655842890e432df4736b3553feb3c7cd2d6"
            UserDefaults.standard.set(map_key, forKey: "token_map")
        }
        guard let url = URL(string: "wss://api.geops.io/tracker-ws/v1/?key=\(map_key)") else { return }
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        var boundbox: String
        // boundbox = "819862.6976440828 5929181.685732176 843405.3023559172 5938736.3142678235"; // Dit is Bern
        // boundbox = "1075401.940808419 5866728.345598243 1095724.427047632 5896720.6813848780"; // Dit is berguen
        //boundbox = "\(epsg4326toEpsg3857([(mapRegion.center.longitude-0.2), (mapRegion.center.latitude-0.2)]))";
        // TODO: Maak dit met de locatie mee volgen
        boundbox = "1011017.444807091 5850052.447254116 1156809.715192909 5934664.0327458850"; // Dit is berguen met omgeving
        sendMessage("BBOX \(boundbox) 13 gen=100 mots=subway,rail,ferry,cablecar,gondola,funicular")
        receiveMessage()
        sendMessage("BUFFER 180 100")
        receiveMessage()
    }
    
    func probeerIets() throws -> Bool { return true }
    
    func getStopsTrains(_ id: String) async -> TrainStopContent? {
        let msg = "GET stopsequence_\(id)"
        logger.log("sending msg to the server via websocket: \(msg)")
        
        do {
            try await webSocketTask?.send(.string(msg))
            let messageStop = try await webSocketTask?.receive()
            switch messageStop {
            case let .string(trainStops):
                logger.log("Got the data form the stops: \(trainStops)")
                self.messages.append(trainStops)
                let data = Data(trainStops.utf8)
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
    
    func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                self.logger.error("\(error.localizedDescription)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self.messages.append(text)
                    // JSON parse
                    let trainUpdate: TrainUpdate?
                    do {
                        let data = text.data(using: .utf8)!
                        self.logger.log("There was data from the server")
                        trainUpdate = try? JSONDecoder().decode(TrainUpdate.self, from: data)
                        
                        let _ = try self.probeerIets()// Dit is om de error weg te krijgen
                        
                        if trainUpdate?.source == "websocket" {
                            self.logger.log("Het was een status open bericht")
                            return
                        }
                    } catch let errorOG {
                        self.logger.fault("We konden niet de data decocden deze data: \(text, privacy: .public)")
                        
                        var request = URLRequest(url: URL(string: "http://localhost:8080")!)
                        request.httpMethod = "POST"
                        request.httpBody = "errorJson=\(text)".data(using: .utf8)
                        
                        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                            guard let _ = data else { return }
                            self.logger.log("Req is door gegaan")
                            fatalError("Unable to decode JSON en error: \(String(describing: errorOG.localizedDescription)) ;;;;;; \(text)")
                        }
                        
                        task.resume()
                    }
                    
                    if let trainUpdateSafe = trainUpdate {
                        self.logger.log("TrainUpdate is door en nu locaties toevoegen")
                        for itemks in trainUpdateSafe.content {
                            if let itemk = itemks {
                                self.logger.log("\(itemk.content.geometry.coordinates)")
                                let trainName = " \(itemk.content.properties.tenant.uppercased()) \(itemk.content.properties.type.firstCapitalized) \(itemk.content.properties.line.name)"
                                let clName = itemk.content.properties.line.color
                                let TrueColourName = (clName ?? "#0xff0000").dropFirst(2)
                                let cl = Color(hex: String(TrueColourName))
                                let containsTrainAlready = self.locations.contains { return $0.id == itemk.content.properties.trainID }
                                
                                
                                if !containsTrainAlready {
                                    DispatchQueue.main.async {
                                        self.locations.append(LocationTrain(id: itemk.content.properties.trainID, name: trainName, opData: itemk, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals))
                                    }
                                    self.logger.log("Een nieuw location toegevoeg  name:\(trainName, privacy: .public) en locatie: \(itemk.content.geometry.coordinates, privacy: .public)")
                                } else {
                                    self.logger.log("Het id zit al in de location")
                                }
                                
                                
                                DispatchQueue.main.async {
                                    self.locations = self.locations.map { location in
                                        if location.id == itemk.content.properties.trainID {
                                            return LocationTrain(id: itemk.content.properties.trainID, name: trainName, opData: itemk, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals)
                                        } else {
                                            return location
                                        }
                                    }
                                }
                                
                                
                                /*let testline = MKPolyline(coordinates: testcoords, count: testcoords.count)
                                 for each in 0..<testcoords.count{
                                 let anno = MKPointAnnotation()
                                 anno.coordinate = testcoords[each]
                                 customMkMapV.addAnnotation(anno as MKAnnotation)
                                 }
                                 customMkMapV.addOverlay(testline)*/
                            }
                        }
                    }
                    
                case .data(let data):
                    // Handle binary data
                    self.logger.log("De data is binair")
                    self.logger.log("\(data.debugDescription, privacy: .public)")
                    break
                @unknown default:
                    print("HI")
                    break
                }
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let _ = message.data(using: .utf8) else { return }
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                self.logger.error("Er was een error met het versturen van een  bericht: \(message, privacy: .public) met de error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
