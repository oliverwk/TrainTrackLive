//
//  Models.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 06/04/2024.
//

import Foundation
import SwiftUI
import MapKit

struct LocationTrain: Identifiable, Equatable, CustomStringConvertible {
    var description: String {
        return "{ id: \(id), name: \(name), colour: \(colour), currentCoordinates: \(currentCoordinates), coordinates: \(coordinates), timeIntervals: \(timeIntervals), coordinatesSwiftui: \(coordinatesSwiftUI), coordinateMap: \(coordinateGeo), coordinatesMap: \(coordinatesGeo) }"
    }
    
    let id: String
    let name: String
    let colour: Color
    let from: Town
    let to: Town
    var currentCoordinates: [Float]
    var coordinates: [[Float]]
    let timeIntervals: [[Int]]
    var coordinatesSwiftUI: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(coordinates[0][0]), longitude: CLLocationDegrees(coordinates[0][1]))
    }
    var coordinateGeo: CLLocationCoordinate2D {
        let RealCordinates = epsg3857toEpsg4326(coordinates[0])
        return CLLocationCoordinate2D(latitude: Double(RealCordinates[1]), longitude: Double(RealCordinates[0]))
    }
    
    var coordinatesGeo: [CLLocationCoordinate2D] {
        let cordarr = coordinates
        return cordarr.map {
            let RealCordinates = epsg3857toEpsg4326($0)
            return CLLocationCoordinate2D(latitude: Double(RealCordinates[1]), longitude: Double(RealCordinates[0]))
        }
    }
}

struct Town: Identifiable, Equatable, CustomStringConvertible {
    let id: String
    let name: String
    let coordinates: [Float]
    
    var coordinateGeo: CLLocationCoordinate2D {
        let RealCordinates = epsg4326toEpsg3857(coordinates)
        return CLLocationCoordinate2D(latitude: Double(RealCordinates[1]), longitude: Double(RealCordinates[0]))
    }
    var coordinatesSwiftUI: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(coordinates[0]), longitude: CLLocationDegrees(coordinates[1]))
    }
    
    var description: String {
        return "{ id: \(id), name: \(name), coordinates: \(coordinates), coordinateMap: \(coordinateGeo) }"
    }
}
