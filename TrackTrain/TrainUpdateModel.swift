//
//  TrainUpdateModel.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 10/04/2024.
//

import Foundation

// MARK: - TrainUpdate
struct TrainUpdate: Codable {
    let source: String
    let timestamp: Int
    let clientReference: String
    let content: [TrainUpdateContent?]
    
    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference = "client_reference"
        case content
    }
}

// MARK: - TrainUpdateContent
struct TrainUpdateContent: Codable {
    let source: Source
    let timestamp: Int
    let clientReference: String
    let content: ContentFeature
    
    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference = "client_reference"
        case content
    }
}

// MARK: - ContentFeature
struct ContentFeature: Codable {
    let type: String
    let geometry: Geometry
    let properties: Properties
}

// MARK: - Geometry
struct Geometry: Codable, CustomStringConvertible {
    let type: String
    let coordinates: [[Float]]
    var description: String {
        return "type: \(type), \(coordinates[0]) en \(epsg4326toEpsg3857(coordinates[0])) coordinates: \(coordinates)"
    }
}



// MARK: - Properties
struct Properties: Codable {
    let bounds: [Float]
    let genLevel: Int?
    let genRange: [Int]
    let tenant: String
    let type: String //PropertiesType
    let timeIntervals: [[Int?]]
    let trainID: String
    let eventTimestamp: Int
    let line: Line
    let timestamp: Int
    let state: TrainState?
    let timeSinceUpdate: Int?
    let hasRealtime, hasRealtimeJourney: Bool
    let operatorProvidesRealtimeJourney: OperatorProvidesRealtimeJourney
    let hasJourney: Bool
    let routeIdentifier: String
    let delay: Int?
    
    enum CodingKeys: String, CodingKey {
        case bounds
        case genLevel = "gen_level"
        case genRange = "gen_range"
        case tenant, type
        case timeIntervals = "time_intervals"
        case trainID = "train_id"
        case eventTimestamp = "event_timestamp"
        case line, timestamp, state
        case timeSinceUpdate = "time_since_update"
        case hasRealtime = "has_realtime"
        case hasRealtimeJourney = "has_realtime_journey"
        case operatorProvidesRealtimeJourney = "operator_provides_realtime_journey"
        case hasJourney = "has_journey"
        case routeIdentifier = "route_identifier"
        case delay
    }
}

// MARK: - Line
struct Line: Codable {
    let id: Int
    let name: String
    let color: String?
    let textColor: String?
    let stroke: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, color
        case textColor = "text_color"
        case stroke
    }
}

enum OperatorProvidesRealtimeJourney: String, Codable {
    case maybe = "maybe"
    case unknown = "unknown"
    case no = "no"
    case yes = "yes"
}

enum TrainState: String, Codable {
    case boarding = "BOARDING"
    case driving = "DRIVING"
    case cancelled = "JOURNEY_CANCELLED"
}


enum PropertiesType: String, Codable {
    case bus = "bus"
    case funicular = "funicular"
    case rail = "rail"
    case tram = "tram"
    case gondola = "gondola"
}


enum ContentType: String, Codable {
    case feature = "Feature"
}

enum Source: String, Codable {
    case trajectory = "trajectory"
}

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}
