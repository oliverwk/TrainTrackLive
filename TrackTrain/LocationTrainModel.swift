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
    init(id: String, name: String, colour: Color, from: Town? = nil, to: Town? = nil, coordinates: [[Float]], timeIntervals: [[Int?]], stops: TrainStopContent? = nil, type: TrainType) {
        self.id = id
        self.name = name
        self.colour = colour
        self.from = from
        self.to = to
        self.stops = stops
        self.coordinates = coordinates
        self.timeIntervals = timeIntervals
        self.type = type
    }
    var description: String {
        return "{ id: \(id), name: \(name), colour: \(colour), currentCoordinates: \(currentCoordinates), coordinates: \(coordinates), timeIntervals: \(timeIntervals), coordinatesSwiftui: \(coordinatesSwiftUI), coordinateMap: \(coordinateGeo), coordinatesMap: \(coordinatesGeo) }"
    }
    
    let id: String
    let name: String
    let colour: Color
    let type: TrainType
    let from: Town?
    let to: Town?
    var stops: TrainStopContent?
    var coordinates: [[Float]]
    let timeIntervals: [[Int?]]
    
    var currentCoordinates: [Float] {
        // https://pub.tik.ee.ethz.ch/students/2022-FS/SA-2022-24.pdf
        let tstart = Float(timeIntervals[0][0]!/1000)
        let tend = Float(timeIntervals[timeIntervals.count-1][0]!/1000)
        let tnow = Float(NSDate().timeIntervalSince1970)
        let frac = ((tnow - tstart)+1)/(tend - tstart)
        print("Fraction: \(tnow - tstart) / \(tend - tstart) is: \(frac) and count: \(coordinates.count) and name: \(name)")
        var index = (frac * Float(coordinates.count)) - 1
        
        if index.isInfinite {
            index = 0
            print("The intervals are: \(timeIntervals) of the vehical: \(name)")
        } else if index > Float(coordinates.count) {
            index = Float(coordinates.count - 1)
        }
        print("The middle cord is: \(coordinates[Int(index)]) with index \(index) and \(coordinate(epsg3857toEpsg4326(coordinates[Int(index)])))")
        return epsg3857toEpsg4326(coordinates[Int(index)])
    }
    
    var trajectory: [CLLocationCoordinate2D] {
        var tar: [CLLocationCoordinate2D] = []
        for cordGeo in coordinates {
            let cord = epsg3857toEpsg4326(cordGeo)
            tar.append(coordinate(cord))
        }
        return tar
    }
    
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

enum TrainType: CustomStringConvertible {
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .rail: return "train.side.front.car"
        case .bus: return "bus.fill"
        case .tram: return "tram.fill"
        case .cablecar: return "cablecar"
        case .gondola: return "cabelcar"
        case .funicular: return "tram.fill.tunnel"
        }
      }
    
    case rail, bus, cablecar, gondola, funicular, tram
}
