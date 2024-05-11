//
//  TrainUpdateStruct.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//

import Foundation

// MARK: - TrainStopUpdate
struct TrainStopUpdate: Codable {
    let source: String
    let timestamp: Int
    let clientReference: String
    let content: [TrainStopContent?]
    
    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference = "client_reference"
        case content
    }
}
// MARK: - TrainStopContent
struct TrainStopContent: Codable, Equatable, Identifiable {
    static func == (lhs: TrainStopContent, rhs: TrainStopContent) -> Bool {
        lhs.id == rhs.id
    }
    let id: String
    let color: String?
    let stroke: String?
    let textColor: String?
    let destination: String
    let newDestination: String?
    let longName, routeIdentifier, shortName, type: String
    let stations: [TrainStopStation]
    let tenant: String
    let publisher: String?
    let publisherURL: String?
    let contentOperator: String
    let operatorURL: String?
    let license, licenseURL, licenseNote: String?

    enum CodingKeys: String, CodingKey {
        case id, color, stroke
        case textColor = "text_color"
        case destination
        case newDestination = "new_destination"
        case longName, routeIdentifier, shortName, type, stations, tenant, publisher
        case publisherURL = "publisherUrl"
        case contentOperator = "operator"
        case operatorURL = "operatorUrl"
        case license
        case licenseURL = "licenseUrl"
        case licenseNote
    }
}

// MARK: - TrainStopStation
struct TrainStopStation: Codable {
    let state: String?
    let formationID: String?
    let arrivalDelay: Int?
    let arrivalTime, aimedArrivalTime: Int?
    let cancelled: Bool
    let departureDelay: Int?
    let departureTime, aimedDepartureTime: Int?
    let noDropOff, noPickUp: Bool
    let stationID: String?
    let stationName: String
    let coordinate: [Int]

    enum CodingKeys: String, CodingKey {
        case state
        case formationID = "formation_id"
        case arrivalDelay, arrivalTime, aimedArrivalTime, cancelled, departureDelay, departureTime, aimedDepartureTime, noDropOff, noPickUp
        case stationID = "stationId"
        case stationName, coordinate
    }
}


