//
//  LocationTrain.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//

import Foundation
import MapKit
import SwiftUI

struct LocationTrain: Identifiable {
    let id: String
    let name: String
    let opData: Any
    let colour: Color
    let coordinates: [[Float]]
    let timeIntervals: [[Int]]
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
    var middleCoordinatesMap: CLLocationCoordinate2D {
        // https://pub.tik.ee.ethz.ch/students/2022-FS/SA-2022-24.pdf
        let tstart = Float(timeIntervals[0][0]/1000)
        let tend = Float(timeIntervals[timeIntervals.count-1][0]/1000)
        let tnow = Float(NSDate().timeIntervalSince1970)
        let frac = ((tnow - tstart)+1)/(tend - tstart)
        print(" \(tnow - tstart) / \(tend - tstart)")
        print("frac: \(frac) and count: \(coordinates.count)")
        let index = (frac * Float(coordinates.count)) - 1
        
        // let index = Float(coordinatesMap.count/2)
        print("the mid cord index: \(index)")
        print("the mid cord index: \(coordinatesMap[Int(index)])")
        return coordinatesMap[Int(index)]
    }
   
}
