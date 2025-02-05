//
//  StravaHealth.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 25/01/2025.
//

import SwiftUI
import HealthKit
import HealthKitUI
import CoreLocation
import MapKit

struct StravaHealth: View {
    
    @State var authenticated = false
    @State var trigger = false
    let healthStore = HKHealthStore()
    @State var stepCountToday = [1,2,3,4,5,6,7,8]
    @State var works: [Works] = []
    @State var sWorks: [SWork] = []
    
    
    @State var mapsAdded = 0
    @State var woksAdded = 0
    @State var stravasAdded = 0
    @State var btncl: Color = .blue
    @State var dateWithoutData = ""
    
    @State var gpxwoks = []
    @State var gpxString = """
    <?xml version="1.0" encoding="UTF-8"?>
    <gpx
      version="1.1"
      creator="Studio Wttp Knng - https://wittopkoning.nl"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns="http://www.topografix.com/GPX/1/1"
      xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
      xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
    """
    
    let allTypes: Set = [
        HKQuantityType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.runningPower),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.runningSpeed),
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRate),
    ]
    
    let read : Set = [
        HKQuantityType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.runningPower),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.runningSpeed),
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRate),
        HKSeriesType.activitySummaryType(),
        HKSeriesType.workoutRoute(),
        HKObjectType.workoutType()
    ]
    
    func readWorkouts() async -> [HKWorkout]? {
        let running = HKQuery.predicateForWorkouts(with: .running)
        
        let samples = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            healthStore.execute(HKSampleQuery(sampleType: .workoutType(), predicate: running, limit: HKObjectQueryNoLimit,sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)], resultsHandler: { query, samples, error in
                if let hasError = error {
                    continuation.resume(throwing: hasError)
                    return
                }
                
                guard let samples = samples else {
                    fatalError("*** Invalid State: This can only fail if there was an error. ***")
                }
                
                continuation.resume(returning: samples)
            }))
        }
        
        guard let workouts = samples as? [HKWorkout] else {
            return nil
        }
        
        return workouts
    }
    
    func GetHearrate(startDate: Date, endDate: Date) async -> [HKSample]? {
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let hrs = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            healthStore.execute(HKSampleQuery(sampleType: HKQuantityType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, limit: HKObjectQueryNoLimit,sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)], resultsHandler: { query, samples, error in
                if let hasError = error {
                    continuation.resume(throwing: hasError)
                    return
                }
                
                guard let samples = samples else {
                    fatalError("*** Invalid State: This can only fail if there was an error. ***")
                }
                
                continuation.resume(returning: samples)
            }))
        }
        
        return hrs
    }
    
    func getLocationDataForRoute(idx: Int, addToGPXStrava: Bool = false) async {
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType(),  HKSeriesType.workoutRoute(), HKQuantityType.workoutType(),]
        if works[idx].polyline?.count != 0 {
            if sWorks[idx].hrs?.count == 0 || sWorks[idx].hrs?.count == nil {
                // Dit is geen hartslag, geen kaart
            } else {
                // Dit is als wel hartslag, maar geen kaart
            }
        }
        
        if idx == sWorks.count {
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("Authorization request failed: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("Authorization granted for route with idx: \(idx)")
                
                let runningObjectQuery = HKQuery.predicateForObjects(from: works[idx].work)
                let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
                    
                    guard error == nil else {
                        // Handle any errors here.
                        fatalError("The initial query failed. \(String(describing: error))")
                    }
                    
                    // Process the initial route data here.
                    if samples?.count == 0 {
                        // Er is geen route data bij deze workout voor data dan thuis als default data weergeven
                        /*31-05-2024 20-11-2021 28-09-2021*/
                        //makeMap(locations: [CLLocation(coordinate: CLLocationCoordinate2D(latitude: 52.13, longitude: 5.03), altitude: 0, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: works[idx].work.startDate)], addToGPXStrava: addToGPXStrava, idx)
                        dateWithoutData += " \(works[idx].work.startDate.ISO8601Format())"
                        
                    } else {
                        
                        let rr = samples?[0]
                        Task {
                            let locations = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
                                var allLocations: [CLLocation] = []
                                
                                // Create the route query.
                                let query = HKWorkoutRouteQuery(route: rr as! HKWorkoutRoute) { (query, locationsOrNil, done, errorOrNil) in
                                    
                                    if let error = errorOrNil {
                                        continuation.resume(throwing: error)
                                        return
                                    }
                                    
                                    guard let currentLocationBatch = locationsOrNil else {
                                        fatalError("*** Invalid State: This can only fail if there was an error. ***")
                                    }
                                    
                                    allLocations.append(contentsOf: currentLocationBatch)
                                    
                                    if done {
                                        continuation.resume(returning: allLocations)
                                        print("Making map with \(addToGPXStrava)")
                                        makeMap(locations: allLocations, addToGPXStrava: addToGPXStrava, idx)
                                    }
                                }
                                
                                healthStore.execute(query)
                            }
                            print(locations)
                        }
                    }
                }
                healthStore.execute(routeQuery)
            } else {
                print("Authorization denied")
            }
        }
    }
    
    func makeMap(locations: [CLLocation], addToGPXStrava: Bool = false, _ idx: Int) {
        if addToGPXStrava {
            sWorks[idx].cords = locations
            mapsAdded += 1
        }
        works[idx].polyline = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
    }
    
    func AddToSWorks(wok: HKWorkout?, idx: Int) {
        var Sname = "run"
        if Calendar.current.component(.hour, from: wok!.startDate) > 20 {
            Sname = "Late Night Run"
        } else if Calendar.current.component(.hour, from: wok!.startDate) > 18 {
            Sname = "Night Run"
        } else if Calendar.current.component(.hour, from: wok!.startDate) > 14 {
            Sname = "Afternoon Run"
        } else if Calendar.current.component(.hour, from: wok!.startDate) > 12 {
            Sname = "Lunch Run"
        } else if Calendar.current.component(.hour, from: wok!.startDate) > 8 {
            Sname = "Morning Run"
        } else if Calendar.current.component(.hour, from: wok!.startDate) > 6 {
            Sname = "Early Morning Run"
        }
        
        let distance = wok?.statistics(for: .init(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: HKUnit.meter())
        let sDate = (wok?.startDate.ISO8601Format())!
        let dur = wok?.duration
        let swork = SWork(name: Sname, start_date_local: sDate, elapsed_time: Int(dur!), distance: distance!, cords: [])
        sWorks.append(swork)
        woksAdded += 1
        
        Task {
            if sWorks[idx].start_date_local != sDate {
                return
            }
            
            let hrs = await GetHearrate(startDate: wok!.startDate, endDate: wok!.endDate)
            var shrs: [(Date, Int)] = []
            for hr in hrs ?? [] {
                let myHR = (hr as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min"))
                shrs.append((hr.startDate, Int(myHR ?? 0)))
            }
            sWorks[idx].hrs = shrs
            await getLocationDataForRoute(idx: idx, addToGPXStrava: true)
        }
    }
    
    var body: some View {
        Text("Hello you have \(stepCountToday) steps")
            .padding(5)
        Button("Convert to Strava") {
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0]
            let docURL = URL(string: documentsDirectory)!
            let dataPath = docURL.appendingPathComponent("stravas")
            if !FileManager.default.fileExists(atPath: dataPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            //for idx in 15..<sWorks.count { // make sure that only data from before 14-12-2024 (that is index 14 and higher) is entreted into the gpx file
            if true {
                let idx = 1
            // reset the string with at each new workout
                    gpxString = """
                 <?xml version="1.0" encoding="UTF-8"?>
                 <gpx
                   version="1.1"
                   creator="Apple Watch SE"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xmlns="http://www.topografix.com/GPX/1/1"
                   xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
                   xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
                   <metadata>
                    <time>\(sWorks[idx].start_date_local)</time>
                   </metadata>
                  <trk>
                   <name>\(sWorks[idx].name)</name>
                   <type>running</type>
                   <trkseg>
                 
                 """
                    let swok = sWorks[idx]
                    sWorks[idx].hrs? = Array(swok.hrs?.reversed() ?? [])
                    for i in 0..<swok.cords.count {
                        let hrr = sWorks[idx].hrs?.filter { abs($0.0.timeIntervalSinceReferenceDate - (sWorks[idx].cords[i]?.timestamp.timeIntervalSinceReferenceDate ?? 0.0)) < 15}
                        
                        if (hrr?.count ?? 0) > 0 {
                            if hrr?.count == 1 {
                                let hr = hrr![0].1
                                gpxString += "<trkpt lat=\"\(swok.cords[i]?.coordinate.latitude ?? 0.0)\" lon=\"\(swok.cords[i]?.coordinate.longitude ?? 0.0)\"><ele>\(swok.cords[i]?.altitude ?? 0.0)</ele><time>\(swok.cords[i]?.timestamp.ISO8601Format() ?? "no date")</time><extensions><gpxtpx:TrackPointExtension><gpxtpx:hr>\(hr)</gpxtpx:hr></gpxtpx:TrackPointExtension></extensions></trkpt>\n\r"
                            } else if (hrr?.count ?? 0) > 1 {
                                let hr = hrr![Int(hrr!.count/2)].1
                                gpxString += "<trkpt lat=\"\(swok.cords[i]?.coordinate.latitude ?? 0.0)\" lon=\"\(swok.cords[i]?.coordinate.longitude ?? 0.0)\"><ele>\(swok.cords[i]?.altitude ?? 0.0)</ele><time>\(swok.cords[i]?.timestamp.ISO8601Format() ?? "no date")</time><extensions><gpxtpx:TrackPointExtension><gpxtpx:hr>\(hr)</gpxtpx:hr></gpxtpx:TrackPointExtension></extensions></trkpt>\n\r"
                            }
                        }
                        else {
                            gpxString += "<trkpt lat=\"\(swok.cords[i]?.coordinate.latitude ?? 0.0)\" lon=\"\(swok.cords[i]?.coordinate.longitude ?? 0.0)\"><ele>\(swok.cords[i]?.altitude ?? 0.0)</ele><time>\(swok.cords[i]?.timestamp.ISO8601Format() ?? "no date")</time></trkpt>\n\r"
                        }
                    }
                    gpxString += "</trkseg></trk></gpx>"
                   
                    //let pasteboard = UIPasteboard.general
                    //pasteboard.string = gpxString
                    
                    gpxwoks.append(pser(filename: "\(swok.start_date_local).gpx", name: "\(swok.name)"))
                    stravasAdded += 1
                    
                    let filename = getDocumentsDirectory().appendingPathComponent("\(swok.start_date_local).gpx")
                    do {
                        try gpxString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                        print("\(stravasAdded) written gpxString to \(filename)")
                    } catch {
                        print("Error with writing to disk: \(error.localizedDescription)")
                        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                    }
            }
            print("dateWithoutData: \(dateWithoutData)")
            UIPasteboard.general.string = gpxwoks.description
            let filename = getDocumentsDirectory().appendingPathComponent("thestravas.json")
            do {
                try gpxwoks.description.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Error with writing to disk: \(error.localizedDescription)")
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
            btncl = .orange
        }
        .tint(btncl)
        ProgressView(value: Float(woksAdded), total: 203.0)
            .padding(10)
        ProgressView(value: Float(mapsAdded), total: 203.0)
            .padding(10)
            .tint(.green)
        ProgressView(value: Float(stravasAdded), total: 203.0)
            .padding(10)
            .tint(.orange)
        List(works.indices, id: \.self) { idx in
            VStack {
                Text(works[idx].text)
                
                if works[idx].polyline != nil {
                    if #available(iOS 17.0, *) {
                        Map(interactionModes: []) {
                            MapPolyline(coordinates: works[idx].polyline ?? [])
                                .stroke(.blue, lineWidth: 3)
                        }
                        .frame(height: 250)
                    } else {
                        Text("Not iOS 17.0")
                        // Fallback on earlier versions
                    }
                } else {
                    Button("Get map") {
                        Task {
                            await getLocationDataForRoute(idx: idx)
                        }
                    }
                }
            }
        }
        Button("Get workouts") {
            Task {
                let routes = await readWorkouts()
                for number in 0..<routes!.count {
                    let wok = routes?[number]
                    print("on \(String(describing: wok?.endDate.formatted(.dateTime))) with duration \(String(format: "%.1f", (wok?.duration ?? 0.0)/60)) min and nr \(number) and \(String(describing: wok?.allStatistics))")
                    let distance = wok?.statistics(for: .init(.distanceWalkingRunning))?.sumQuantity()
                    let cals = wok?.statistics(for: .init(.activeEnergyBurned))?.sumQuantity()
                    works.append(Works(text: "Distance is \(Int(distance?.doubleValue(for: HKUnit.meter()) ?? 0.0)/1000) km with duration \(String(format: "%.1f", (wok?.duration ?? 0.0)/60)) min on \(wok?.endDate.formatted(.dateTime) ?? Date().formatted(.dateTime)) and burned \(Int(cals?.doubleValue(for: HKUnit.largeCalorie()) ?? 0.0)) kcals", work: wok!))
                    AddToSWorks(wok: wok, idx: number)
                    
                }
                
            }
        }
        
        if #available(iOS 17.0, *) {
            Button("Access health data") {
                // OK to read or write HealthKit data here.
                readStepCountThisWeek()
            }
            .disabled(!authenticated)
            
            // If HealthKit data is available, request authorization
            // when this view appears.
            .onAppear {
                
                // Check that Health data is available on the device.
                if HKHealthStore.isHealthDataAvailable() {
                    // Modifying the trigger initiates the health data
                    // access request.
                    trigger.toggle()
                }
            }
            
            // Requests access to share and read HealthKit data types
            // when the trigger changes.
            .healthDataAccessRequest(store: healthStore,
                                     shareTypes: allTypes,
                                     readTypes: allTypes,
                                     trigger: trigger) { result in
                switch result {
                    
                case .success(_):
                    authenticated = true
                case .failure(let error):
                    // Handle the error here.
                    fatalError("*** An error occurred while requesting authentication: \(error) ***")
                }
            }
        } else {
            // Fallback on earlier versions
            Text("No ios 17")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func readStepCountThisWeek() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find the start date (Monday) of the current week
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            print("Failed to calculate the start date of the week.")
            return
        }
        
        // Find the end date (Sunday) of the current week
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            print("Failed to calculate the end date of the week.")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfWeek,
            end: endOfWeek,
            options: .strictStartDate
        )
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum, // fetch the sum of steps for each day
            anchorDate: startOfWeek,
            intervalComponents: DateComponents(day: 1) // interval to make sure the sum is per 1 day
        )
        
        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                if let error = error {
                    print("An error occurred while retrieving step count: \(error.localizedDescription)")
                }
                return
            }
            
            result.enumerateStatistics(from: startOfWeek, to: endOfWeek) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                    let day = calendar.component(.weekday, from: statistics.startDate)
                    self.stepCountToday[day] = steps
                }
            }
        }
        
        healthStore.execute(query)
    }
    
}


#Preview {
    StravaHealth()
}
