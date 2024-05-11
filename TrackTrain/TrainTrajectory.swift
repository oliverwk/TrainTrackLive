//
//  TrainTrajectory.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 12/04/2024.
//

import Foundation


// MARK: - TrainTrajectory
struct TrainTrajectory: Codable {
    let source: String
    let timestamp: Int
    let clientReference: String?
    let content: Content

    enum CodingKeys: String, CodingKey {
        case source, timestamp
        case clientReference
        case content
    }
}

// MARK: - Content
struct Content: Codable {
    let type: String
    let features: [Feature]
    let properties: ContentProperties
}

// MARK: - Feature
struct Feature: Codable {
    let type: String
    let geometry: FeatureGeometry
    let properties: FeatureProperties
}

// MARK: - FeatureGeometry
struct FeatureGeometry: Codable {
    let type: String
    let geometries: [GeometryElement]
}

// MARK: - GeometryElement
struct GeometryElement: Codable {
    let type: String
    let coordinates: [[Int]]
}

// MARK: - FeatureProperties
struct FeatureProperties: Codable {
    let trainID: String
    let genLevel: Int?
    let genRange: [Int]
    let journeyID, lineID: Int
    let stroke, lineName, type: String
    let eventTimestamp: Int

    enum CodingKeys: String, CodingKey {
        case trainID = "train_id"
        case genLevel = "gen_level"
        case genRange = "gen_range"
        case journeyID = "journey_id"
        case lineID = "line_id"
        case stroke
        case lineName = "line_name"
        case type
        case eventTimestamp = "event_timestamp"
    }
}

// MARK: - ContentProperties
struct ContentProperties: Codable {
    let trainID: String
    let genLevel: Int?
    let genRange: [Int]
    let tenant: String
    let publisher: String?
    let publisherUrl: String?
    let propertiesOperator: String
    let operatorUrl: String
    let license, licenseUrl, licenseNote: String?

    enum CodingKeys: String, CodingKey {
        case trainID = "train_id"
        case genLevel = "gen_level"
        case genRange = "gen_range"
        case tenant, publisher
        case publisherUrl
        case propertiesOperator  = "operator"
        case operatorUrl
        case license
        case licenseUrl
        case licenseNote
    }
}
