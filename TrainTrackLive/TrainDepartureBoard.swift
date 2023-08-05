//
//  TrainDepartureBoard.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 05/08/2023.
//

import Foundation
import MapKit


// MARK: - TrainDepartureBoard
struct TrainDepartureBoard: Codable {
    let station: TrainStation
    let stationboard: [Stationboard]
}

// MARK: - TrainStation
struct TrainStation: Codable {
    let id: String
    let name: String?
    let score: String?
    let coordinate: Coordinate
    let distance: Double?
}

// MARK: - Coordinate
struct Coordinate: Codable {
    let type: TypeEnum
    let x, y: Double?
    var swiftCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(x ?? 46.631067), longitude: CLLocationDegrees(y ?? 9.746749))
    }
}

enum TypeEnum: String, Codable {
    case wgs84 = "WGS84"
}

// MARK: - Stationboard
struct Stationboard: Codable {
    let stop: Stop
    let name, category: String
    let subcategory, categoryCode: String?
    let number, stationboardOperator, to: String
    let passList: [PassList]
    let capacity1St, capacity2Nd: String?

    enum CodingKeys: String, CodingKey {
        case stop, name, category, subcategory, categoryCode, number
        case stationboardOperator = "operator"
        case to, passList
        case capacity1St = "capacity1st"
        case capacity2Nd = "capacity2nd"
    }
}

// MARK: - PassList
struct PassList: Codable {
    let station: TrainStation
    let arrival: Date?
    let arrivalTimestamp: Int?
    let departure: Date?
    let departureTimestamp: Int?
    let delay: Int
    let platform: String?
    let prognosis: Prognosis
    let realtimeAvailability: Bool?
    let location: TrainStation
}

// MARK: - Prognosis
struct Prognosis: Codable {
    let platform: String?
    let arrival: Date
    let departure: Date?
    let capacity1St, capacity2Nd: String?

    enum CodingKeys: String, CodingKey {
        case platform, arrival, departure
        case capacity1St = "capacity1st"
        case capacity2Nd = "capacity2nd"
    }
}

// MARK: - Stop
struct Stop: Codable {
    let station: TrainStation
    let arrival, arrivalTimestamp: String?
    let departure: Date
    let departureTimestamp, delay: Int
    let platform: String?
    let prognosis: Prognosis
    let realtimeAvailability: Bool?
    let location: TrainStation
}
