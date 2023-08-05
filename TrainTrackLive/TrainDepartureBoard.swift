//
//  TrainDepartureBoard.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 05/08/2023.
//

import Foundation
import MapKit
import SwiftUI

// MARK: - TrainDepartureBoard
struct TrainDepartureBoard: Codable, CustomDebugStringConvertible {
    let station: TrainStation
    let stationboard: [Stationboard]
    var debugDescription: String {
        return "station: \(station), stationboard: \(stationboard.debugDescription)"
    }
}

// MARK: - TrainStation
struct TrainStation: Codable, Identifiable, CustomStringConvertible {
    let id: String
    let name: String?
    let score: String?
    let coordinate: Coordinate
    let distance: String?
    var description: String {
        return "id: \(id), name: \(String(describing: name)), score: \(String(describing: score)), coordinate \(coordinate.swiftCoordinate), distance: \(String(describing: distance))"
    }
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
struct Stationboard: Codable, Identifiable {
    let id = UUID()
    let stop: Stop
    let name, category: String
    let subcategory, categoryCode: String?
    let number, stationboardOperator, to: String
    let passList: [PassList]
    let capacity1St, capacity2Nd: String?
    let tapped = false
   
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
    let arrival:  String?// Date?
    var arrivalDate: Date {
        return Date(timeIntervalSince1970: Double(arrivalTimestamp ?? Int(Date.now.timeIntervalSince1970)))
    }
    let arrivalTimestamp: Int?
    let departureTime: String?// Date?
    let departureTimestamp: Int?
    var departureDate: Date {
        return Date(timeIntervalSince1970: Double(departureTimestamp!))
    }
    let delay: Int?
    let platform: String?
    let prognosis: Prognosis
    let realtimeAvailability: Bool?
    let location: TrainStation
    enum CodingKeys: String, CodingKey {
        case station,arrival,arrivalTimestamp,departureTimestamp,delay,platform,prognosis,realtimeAvailability,location
        case departureTime = "departure"
    }
}

// MARK: - Prognosis
struct Prognosis: Codable {
    let platform: String?
    let arrival: String?// Date?
    let departureTime: String?// Date?
    let capacity1St, capacity2Nd: String?

    enum CodingKeys: String, CodingKey {
        case platform, arrival
        case departureTime = "departure"
        case capacity1St = "capacity1st"
        case capacity2Nd = "capacity2nd"
    }
}

// MARK: - Stop
struct Stop: Codable {
    let station: TrainStation
    let arrival: String?
    let arrivalTimestamp: Int?
    var arrivalDate: Date {
        return Date(timeIntervalSince1970: Double(arrivalTimestamp ?? Int(Date.now.timeIntervalSince1970)))
    }
    let departureTime: String?// Date?
    let departureTimestamp, delay: Int?
    var departureDate: Date {
        return Date(timeIntervalSince1970: Double(departureTimestamp ?? Int(Date.now.timeIntervalSince1970)))
    }
    let platform: String?
    let prognosis: Prognosis
    let realtimeAvailability: Bool?
    let location: TrainStation
    enum CodingKeys: String, CodingKey {
        case station,arrival,arrivalTimestamp,departureTimestamp,delay,platform,prognosis,realtimeAvailability,location
        case departureTime = "departure"
    }
}
