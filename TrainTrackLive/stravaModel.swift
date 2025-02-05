//
//  stravaModel.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 25/01/2025.
//

import Foundation
import HealthKit
import CoreLocation

struct pser: CustomStringConvertible {
    var filename: String
    var name: String
    var description: String {
        return "{\"filename\": \(filename), \"name\": \(name)}"
    }
}

struct Works: Identifiable {
    let id = UUID()
    var text: String
    var work: HKWorkout
    var polyline: [CLLocationCoordinate2D]?
}


struct SWork {
    let name: String
    let start_date_local: String //required Date, in form    ISO 8601 formatted date time.
    let elapsed_time: Int //required Integer, in form    In seconds.
    let distance: Double
    let commute = 0
    var cords: [CLLocation?]
    var hrs: [(Date, Int)]?
}
