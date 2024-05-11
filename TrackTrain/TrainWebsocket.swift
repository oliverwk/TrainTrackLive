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
    var SUrl = URL(string: "about:blank")
    
    private var webSocketTask: URLSessionWebSocketTask?
    let logger = Logger(
        subsystem: "nl.wittopkoning.tracktrain",
        category: "TrainWebsocket"
    )
    /// Conneting to the websocket connection and initaling it with the correct to location as search circle
    /// - Parameter location: The center point of the search circle on the map
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
            webSocketTask?.cancel()
            self.logger.log("Disconnted with socket")
        }
        guard let url = URL(string: "wss://api.geops.io/tracker-ws/v1/ws?key=\(map_key)") else { return }
        SUrl = url
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // boundbox = "819862.6976440828 5929181.685732176 843405.3023559172 5938736.3142678235"; // Dit is Bern
        // boundbox = "1075401.940808419 5866728.345598243 1095724.427047632 5896720.6813848780"; // Dit is berguen
        boundbox = createBoundBox(location)
        self.logger.log("connected with box: \(self.boundbox, privacy: .public)")
        
        sendMessage("BBOX \(boundbox) 13") // gen=100 mots=tram,subway,rail,bus,ferry,cablecar,gondola,funicular,coach")
        // BBOX <left> <bottom> <right> <top> <zoom>[ tenant=<tenant>][ gen=<generalization>][ mots=<mot1,mot2,...>]
        receiveMessage()
        sendMessage("BUFFER 180 100")
        receiveMessage()
        receiveMessage()
    }
    
    func handleTrainData(data: Data) {
        do {
            
            let trainUpdate = try JSONDecoder().decode(TrainUpdate.self, from: data)
            self.logger.log("TrainUpdate is goed en nu \(trainUpdate.content.count) locaties toevoegen")

            for itemks in trainUpdate.content {
                    if let itemk = itemks {
                        var operators = itemk.content.properties.tenant.uppercased().replacingOccurrences(of: "DE-GTFS-DE", with: "DB").replacingOccurrences(of: "BELGIUM-RAIL", with: "SNCB")
                        if itemk.content.properties.contentOperator != nil {
                            operators = itemk.content.properties.contentOperator!
                        }
                        let trainName = "\(operators) \(itemk.content.properties.type.firstCapitalized) \(itemk.content.properties.line.name)"
                        let clName = itemk.content.properties.line.color
                        let TrueColourName = (clName ?? "#007bff").dropFirst(1)
                        let cl = Color(hex: String(TrueColourName))
                        let containsTrainAlready = self.locations.contains { return $0.id == itemk.content.properties.trainID }
                        let trainType: TrainType
                        
                        switch itemk.content.properties.type {
                        case "rail":
                            trainType = .rail
                        case "bus":
                            trainType = .bus
                        case "tram":
                            trainType = .tram
                        case "cabelcar":
                            trainType = .cablecar
                        case "gondola":
                            trainType = .gondola
                        case "funicular":
                            trainType = .funicular
                        default:
                            trainType = .rail
                            self.logger.log("There was a default with: \(itemk.content.properties.type, privacy: .public)")
                        }
                        
                        if !containsTrainAlready {
                            DispatchQueue.main.async {
                                self.locations.append(LocationTrain(id: itemk.content.properties.trainID, name: trainName, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals, type: trainType))
                            }
                            self.logger.log("Een nieuw location toegevoegen met name:\(trainName, privacy: .public) en beginlocatie: \(itemk.content.geometry.coordinates[0], privacy: .public)")
                        } else {
                            self.logger.log("Het id zit al in de location")
                            let indexTrain = self.locations.firstIndex { return $0.id == itemk.content.properties.trainID }
                            DispatchQueue.main.async {
                                self.locations[indexTrain!] = (LocationTrain(id: itemk.content.properties.trainID, name: trainName, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals, type: trainType))
                            }
                        }
                        
                        
                        DispatchQueue.main.async {
                            self.locations = self.locations.map { location in
                                if location.id == itemk.content.properties.trainID {
                                    return LocationTrain(id: itemk.content.properties.trainID, name: trainName, colour: cl, coordinates: itemk.content.geometry.coordinates, timeIntervals: itemk.content.properties.timeIntervals, type: trainType)
                                } else {
                                    return location
                                }
                            }
                        }
                }
            }
        } catch {
            // Hier nog een manier maken voor als er een source == deleted vehicals
            self.logger.log("Er was een error met json van de websocket bericht met error \(String(describing: error), privacy: .public)")
        }
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
                    self.logger.log("There was data from the server \(text, privacy: .public)")
                    do {
                        let data = text.data(using: .utf8)!
                        let updateMessage = try JSONDecoder().decode(TrainUpdateMessage.self, from: data)
                        if (updateMessage.source == "websocket") { // als het antwoord op de stops is dan zelf handeln
                            self.logger.log("Het was een status bericht")
                            return
                        } else if (updateMessage.source == "buffer") { // als de source buffer is dan is het (extra) positie data
                            self.handleTrainData(data: data)
                            self.receiveMessage()
                        } else if (updateMessage.source.contains("full_trajectory_")) { // Als er trajectory in zit dan, data goed handeln
                            self.logger.log("Got data from \(updateMessage.source)")
                            let tar = self.handleFullTarjactory(text: text, data: data)
                            let trainid = String(updateMessage.source.split(separator: "full_trajectory_")[0])
                            let trainIndex = self.locations.firstIndex(where: {$0.id == trainid})
                            self.logger.log("Adding trajectory to \(trainIndex ?? 999, privacy: .public) with len of \(tar?.count ?? 0)")
                            DispatchQueue.main.async {
                                self.locations[trainIndex!].trajectory = tar ?? []
                            }
                        } else if (updateMessage.source.contains("stopsequence_")) { // Als er stopsequence_ in zit dan, data toevoegen aan self.locations
                            self.logger.log("Got data from \(updateMessage.source)")
                            let trainStopsJson = try JSONDecoder().decode(TrainStopUpdate.self, from: data)
                            let stops = trainStopsJson.content[0]
                            let trainid = String(updateMessage.source.split(separator: "stopsequence_")[0])
                            let trainIndex = self.locations.firstIndex(where: {$0.id == trainid})
                            self.logger.log("Adding stops \(Int(stops?.stations.count ?? 0), privacy: .public) to \(trainIndex ?? 999, privacy: .public)")
                            DispatchQueue.main.async {
                                self.locations[trainIndex!].stops = stops
                                self.locations[trainIndex!].name = "\(stops?.contentOperator ?? "Iemand") \(stops?.type.firstCapitalized ?? "Iets") \(stops?.longName ?? "ergnes")"
                            }
                        }
                    } catch {
                        self.logger.log("Er was een error met json van de websocket bericht met error \(String(describing: error), privacy: .public)")
                    }
                    break
                case .data(let data):
                    // Handle binary data
                    self.logger.log("De data is binair")
                    self.logger.log("Data: \(data.debugDescription, privacy: .public)")
                    break
                @unknown default:
                    self.logger.log("a default occurred at the handle of the data, no data or error")
                    break
                }
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let _ = message.data(using: .utf8) else { return }
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                self.logger.error("Er was een error met het versturen van een bericht: \(message, privacy: .public) met de error: \(String(describing: error), privacy: .public)")
            }
        }
    }
    
    /// This function is for calling in the ContentView
    /// - Parameter id: The id of the train to get the trajctory of.
    func getFullTarjactoryTrains(_ id: String)  {
        let msg = "GET full_trajectory_\(id)"
        logger.log("sending msg to the server via websocket: \(msg)")
        if ((webSocketTask?.state != nil) && (webSocketTask?.state != .running)) {
            // terminate the websocket or (re)connect
            let request = URLRequest(url: SUrl!)
            webSocketTask = URLSession.shared.webSocketTask(with: request)
            webSocketTask?.resume()
            self.logger.log("(re)conneting with the socket")
        }
        sendMessage(msg)
        receiveMessage()
        receiveMessage()
    }
    
    /// This function is for calling in the TrainWebsocket class when a websocket message is received
    /// - Parameter id: The id of the train to get the trajctory of.
    /// - Returns: An array of the coordinations representing the full tarjactory of the train.
    func handleFullTarjactory(text: String, data: Data) -> [CLLocationCoordinate2D]? {
        do {
            let trainStopsJson = try JSONDecoder().decode(TrainTrajectory.self, from: data)
            let rawcords = trainStopsJson.content.features[0].geometry.geometries[0].coordinates
            var cords: [CLLocationCoordinate2D] = []
            for rawcord in rawcords {
                let cordr = epsg3857toEpsg4326(rawcord.floats ?? [])
                let lat = cordr[1]
                let long = cordr[0]
                let cord = coordinate(Float(lat), Float(long))
                cords.append(cord)
            }
            return cords
        } catch{
            self.logger.error("We got an error with send and Tar \(text) to the weboscket server or with the receiving met error \(String(describing: error))")
            return nil
        }
    }
    
    /// This function is for calling in the ContentView
    /// - Parameter id: The id of the train to get the stops of.
    func getStopsTrains(_ id: String) {
        let msg = "GET stopsequence_\(id)"
        logger.log("sending msg to the server via websocket: \(msg)")
        
        if ((webSocketTask?.state == nil) || (webSocketTask?.state != .running)) {
            // terminate the websocket or (re)connect
            let request = URLRequest(url: SUrl!)
            webSocketTask = URLSession.shared.webSocketTask(with: request)
            webSocketTask?.resume()
            self.logger.log("(re)conneting with the socket")
            sendMessage("BUFFER 180 100")
        }
        sendMessage(msg)
        receiveMessage()
    }
    
    
    @available(*, deprecated, message: "Parse your data by hand instead")
    func getStopsTrainsDep(_ id: String) async -> TrainStopContent? {
        let msg = "GET stopsequence_\(id)"
        logger.log("sending msg to the server via websocket: \(msg)")
        let messageStop: URLSessionWebSocketTask.Message?
        do {
            try await webSocketTask?.send(.string(msg))
            messageStop = try await webSocketTask?.receive()
            switch messageStop {
            case let .string(trainStops):
                logger.log("Got the data form the stops: \(trainStops)")
                self.messages.append(trainStops)
                //let trainStopss = trainStops.replacingOccurrences(of: ALBULA_TUNNEL_PENDING, with: "").replacingOccurrences(of: ALBULA_TUNNEL_LEAVING, with: "")
                logger.log("Got the data from \(msg)")
                let data = Data(trainStops.utf8)
                
                let updateMessage = try JSONDecoder().decode(TrainUpdateMessage.self, from: data)
                if (updateMessage.source == msg) { // als het antwoord op de stops is dan zelf handleen
                    let trainStopsJson = try JSONDecoder().decode(TrainStopUpdate.self, from: data)
                    return trainStopsJson.content[0]
                } else { // anders was het geen stop, maar een buffer
                    logger.log("Het was geen stops, maar een buffer")
                    handleTrainData(data: data)
                    return nil
                }
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
            self.logger.error("We got an error with send and stops \(msg) to the weboscket server or with the receiving met error \(String(describing: error))")
            return nil
        }
        
    }
}

struct TrainUpdateMessage: Codable {
    let source: String
    let timestamp: Int
    let clientReference: String

    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference = "client_reference"
    }
}

struct TrainUpdateDel: Codable {
    let source: Source
    let timestamp: Int
    let clientReference: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference = "client_reference"
        case content
    }
}
