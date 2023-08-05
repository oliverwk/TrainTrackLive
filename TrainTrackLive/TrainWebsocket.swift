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
        guard let url = URL(string: "wss://api.geops.io/tracker-ws/v1/?key=5cc87b12d7c5370001c1d655d703afb6966843b3a8e5e5cbb3a99320") else { return }
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        var boundbox: String
        // boundbox = "819862.6976440828 5929181.685732176 843405.3023559172 5938736.3142678235"; // Dit is Bern
        // boundbox = "1075401.940808419 5866728.345598243 1095724.427047632 5896720.6813848780"; // Dit is berguen
        //boundbox = "\(epsg4326toEpsg3857([(mapRegion.center.longitude-0.2), (mapRegion.center.latitude-0.2)]))";
        boundbox = "1011017.444807091 5850052.447254116 1156809.715192909 5934664.0327458850"; // Dit is berguen met omgeving
        sendMessage("BBOX \(boundbox) 13 gen=100 mots=subway,rail,ferry,cablecar,gondola,funicular")
        receiveMessage()
        sendMessage("BUFFER 180 100")
        receiveMessage()
    }
    
    func probeerIets() throws -> Bool { return true }
    
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
                    var geoJson = [MKGeoJSONObject]()
                    var overlays = [MKOverlay]()
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
                    
                    for item in geoJson {
                        if let feature = item as? MKGeoJSONFeature {
                            let propData = feature.properties!
                            
                            //  self.logger.info("\(feature.identifier?.debugDescription)")
                            self.logger.info("\(feature.geometry.debugDescription)")
                            self.logger.info("\(propData.debugDescription)")
                            for geo in feature.geometry {
                                if let polygon = geo as? MKPolygon {
                                    overlays.append(polygon)
                                }
                                if let PolyLine = geo as? MKPolyline {
                                    overlays.append(PolyLine)
                                }
                            }
                            
                            // Dit is de geojson porp: LineString
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
