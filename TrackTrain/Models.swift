//
//  Models.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 06/04/2024.
//

import Foundation
import SwiftUI
import MapKit

struct LocationTrain: Identifiable, Equatable {
    let id: String
    let name: String
    let colour: Color
    var coordinates: [[Float]]
    let timeIntervals: [[Int]]
    var coordinatesSwiftui: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(coordinates[0][0]), longitude: CLLocationDegrees(coordinates[0][1]))
    }
    var coordinateMap: CLLocationCoordinate2D {
        let RealCordinates = epsg3857toEpsg4326(coordinates[0])
        return CLLocationCoordinate2D(latitude: Double(RealCordinates[1]), longitude: Double(RealCordinates[0]))
    }
    
    var coordinatesMap: [CLLocationCoordinate2D] {
        let cordarr = coordinates
        return cordarr.map {
            let RealCordinates = epsg3857toEpsg4326($0)
            return CLLocationCoordinate2D(latitude: Double(RealCordinates[1]), longitude: Double(RealCordinates[0]))
        }
    }
}
