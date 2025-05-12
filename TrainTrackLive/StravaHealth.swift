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

import UniformTypeIdentifiers


struct StravaHealth: View {
    
    @State var authenticated = false
    @State var trigger = false
    let healthStore = HKHealthStore()
    @State var stepCountToday = []
    @State var works: [Works] = []
    @State var sWorks: [SWork] = []
    @State var wkType: HKWorkoutActivityType = .running
    @State var wkQauntType : HKQuantityTypeIdentifier = .distanceWalkingRunning
    @State var totQaunt: Double = 0
    @State  var activityonDate = Date.now

    @State var swoksTBadded = 0
    @State var mapsAdded = 0
    @State var woksAdded = 0
    @State var stravasAdded = 0
    @State var btncl: Color = .blue
    @State var dateWithoutData = ""
    @State private var showingExporter = false
    @State private var doctoexport: TextFile = TextFile()
    

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
        // let running = HKQuery.predicateForWorkouts(with: .running)
        let running = HKQuery.predicateForWorkouts(with: wkType)

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
        
        //let distance = wok?.statistics(for: .init(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: HKUnit.meter())
        let distance = wok?.statistics(for: .init(wkQauntType))?.sumQuantity()?.doubleValue(for: HKUnit.meter())

        let sDate = (wok?.startDate.ISO8601Format())!
        let dur = wok?.duration
        let swork = SWork(name: Sname, start_date_local: sDate, elapsed_time: Int(dur!), distance: distance ?? 0, cords: [])
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
        
        Text("\(stepCountToday) steps and total: \(round(totQaunt / 1000)) km and avg \(totQaunt.int/(woksAdded+1)/1000) km")
            .padding(5)
        HStack {
            Picker("Select Type", selection: $wkType) {
                ForEach(1...84, id: \.self) { atype in
                    Text(HKWorkoutActivityType.name(for: HKWorkoutActivityType(rawValue: UInt(atype))!)).tag(HKWorkoutActivityType(rawValue: UInt(atype))!)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Select Quantity", selection: $wkQauntType) {
                ForEach(0...(HKQuantityTypeIdentifier.allCases.count-1), id: \.self) { i_qtype in
                    Text("\(HKQuantityTypeIdentifier.myCases[i_qtype])").tag(HKQuantityTypeIdentifier.allCases[i_qtype])
                }
            }
            .pickerStyle(.menu)
        }
        
        
        ProgressView(value: Float(woksAdded), total: Float(woksAdded))
            .padding(10)
        ProgressView(value: Float(mapsAdded), total: Float(woksAdded))
            .padding(10)
            .tint(.green)
        ProgressView(value: Float(stravasAdded), total: Float(woksAdded))
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
                    HStack {
                        Button("Get map") {
                            Task {
                                await getLocationDataForRoute(idx: idx)
                            }
                        }.buttonStyle(.bordered)
                        Spacer()
                        Button("Share File") {
                            doctoexport = TextFile(initialText: togpxstring(idx: idx, sWorks), ifilename: "\(works[idx].work.startDate.ISO8601Format())-train-run.gpx")
                            showingExporter = true
                        }.buttonStyle(.bordered)
                    }
                    
                }
                if works[idx].polyline != nil {
                    Button("Share File") {
                        doctoexport = TextFile(initialText: togpxstring(idx: idx, sWorks), ifilename: "\(works[idx].work.startDate.ISO8601Format())-train-run.gpx")
                        showingExporter = true
                    }.buttonStyle(.bordered)
                }
                
            }
        }.fileExporter(isPresented: $showingExporter, document: doctoexport, contentType: .plainText) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        HStack {
            VStack {
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
                    }.padding(5)
                } else {
                    // Fallback on earlier versions
                    Text("No ios 17")
                }
                Button("Get workouts") {
                    Task {
                        totQaunt = 0
                        let routes = await readWorkouts()
                        swoksTBadded = routes!.count
                        for number in 0..<routes!.count {
                            let wok = routes?[number]
                            print("on \(String(describing: wok?.endDate.formatted(.dateTime))) with duration \(String(format: "%.1f", (wok?.duration ?? 0.0)/60)) min and nr \(number) and \(String(describing: wok?.allStatistics))")
                            let distance = wok?.statistics(for: .init(wkQauntType))?.sumQuantity()
                            totQaunt += distance?.doubleValue(for: HKUnit.meter()) ?? 0
                            let cals = wok?.statistics(for: .init(.activeEnergyBurned))?.sumQuantity()
                            works.append(Works(text: "Distance is \(Int(distance?.doubleValue(for: HKUnit.meter()) ?? 0.0)/1000) km with duration \(String(format: "%.1f", (wok?.duration ?? 0.0)/60)) min on \(wok?.endDate.formatted(.dateTime) ?? Date().formatted(.dateTime)) and burned \(Int(cals?.doubleValue(for: HKUnit.largeCalorie()) ?? 0.0)) kcals", work: wok!))
                            AddToSWorks(wok: wok, idx: number)
                            
                        }
                        
                    }
                }.padding(5)
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
                    
                    for idx in 0..<sWorks.count { // make sure that only data from before 14-12-2024 (that is index 14 and higher) is entreted into the gpx file
                        //let idx = 0
                        //if true {
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
                .padding(5)
                .tint(btncl)
            }
            
            
            if #available(iOS 17.0, *) {
                DatePicker(selection: $activityonDate, in: ...Date.now, displayedComponents: .date) {
                    Text("Select a date")
                }.onChange(of: activityonDate) { ov, nv in
                    var TokeepUUIDs: [String] = []
                    for work in works {
                        if work.work.startDate.timeIntervalSince1970 < nv.timeIntervalSince1970 {
                            // Als het eerder is gebrud dat geselcteerde datum
                            TokeepUUIDs.append(work.id.uuidString)

                        } else {
                            // Als het later is gebrud dat geselcteerde datum
                        }
                    }
                    // filter list of works
                    works = works.filter { wid in
                        var tokeep = false
                        for kuuid in TokeepUUIDs {
                            if wid.id.uuidString == kuuid {
                                tokeep = true
                            }
                        }
                        return tokeep
                    }
                    
                }
                .padding(5)
            }
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
                    // let weekday = calendar.component(.weekday, from: statistics.startDate)
                    self.stepCountToday.append(steps)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
}

extension HKQuantityTypeIdentifier: @retroactive CaseIterable {
    public static var myCases: [String] = ["appleSleepingWristTemperature","bodyFatPercentage","bodyMass","bodyMassIndex","electrodermalActivity","height","leanBodyMass","waistCircumference","activeEnergyBurned","appleExerciseTime","appleMoveTime","appleStandTime","basalEnergyBurned","crossCountrySkiingSpeed","cyclingCadence","cyclingFunctionalThresholdPower","cyclingPower","cyclingSpeed","distanceCrossCountrySkiing","distanceCycling","distanceDownhillSnowSports","distancePaddleSports","distanceRowing","distanceSkatingSports","distanceSwimming","distanceWalkingRunning","distanceWheelchair","estimatedWorkoutEffortScore","flightsClimbed","nikeFuel","paddleSportsSpeed","physicalEffort","pushCount","rowingSpeed","runningPower","runningSpeed","stepCount","swimmingStrokeCount","underwaterDepth","workoutEffortScore","environmentalAudioExposure","environmentalSoundReduction","headphoneAudioExposure","atrialFibrillationBurden","heartRate","heartRateRecoveryOneMinute","heartRateVariabilitySDNN","peripheralPerfusionIndex","restingHeartRate","vo2Max","walkingHeartRateAverage","appleWalkingSteadiness","runningGroundContactTime","runningStrideLength","runningVerticalOscillation","sixMinuteWalkTestDistance","stairAscentSpeed","stairDescentSpeed","walkingAsymmetryPercentage","walkingDoubleSupportPercentage","walkingSpeed","walkingStepLength","dietaryBiotin","dietaryCaffeine","dietaryCalcium","dietaryCarbohydrates","dietaryChloride","dietaryCholesterol","dietaryChromium","dietaryCopper","dietaryEnergyConsumed","dietaryFatMonounsaturated","dietaryFatPolyunsaturated","dietaryFatSaturated","dietaryFatTotal","dietaryFiber","dietaryFolate","dietaryIodine","dietaryIron","dietaryMagnesium","dietaryManganese","dietaryMolybdenum","dietaryNiacin","dietaryPantothenicAcid","dietaryPhosphorus","dietaryPotassium","dietaryProtein","dietaryRiboflavin","dietarySelenium","dietarySodium","dietarySugar","dietaryThiamin","dietaryVitaminA","dietaryVitaminB12","dietaryVitaminB6","dietaryVitaminC","dietaryVitaminD","dietaryVitaminE","dietaryVitaminK","dietaryWater","dietaryZinc","bloodAlcoholContent","bloodPressureDiastolic","bloodPressureSystolic","insulinDelivery","numberOfAlcoholicBeverages","numberOfTimesFallen","timeInDaylight","uvExposure","waterTemperature","basalBodyTemperature","appleSleepingBreathingDisturbances","forcedExpiratoryVolume1","forcedVitalCapacity","inhalerUsage","oxygenSaturation","peakExpiratoryFlowRate","respiratoryRate","bloodGlucose","bodyTemperature"]
    public static var allCases: [HKQuantityTypeIdentifier] {
        return [HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleSleepingWristTemperature"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyFatPercentage"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyMass"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyMassIndex"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierElectrodermalActivity"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeight"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierLeanBodyMass"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWaistCircumference"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierActiveEnergyBurned"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleExerciseTime"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleMoveTime"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleStandTime"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBasalEnergyBurned"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCrossCountrySkiingSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingCadence"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingFunctionalThresholdPower"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingPower"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceCrossCountrySkiing"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceCycling"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceDownhillSnowSports"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistancePaddleSports"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceRowing"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceSkatingSports"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceSwimming"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceWalkingRunning"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceWheelchair"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEstimatedWorkoutEffortScore"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierFlightsClimbed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNikeFuel"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPaddleSportsSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPhysicalEffort"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPushCount"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRowingSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningPower"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStepCount"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierSwimmingStrokeCount"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierUnderwaterDepth"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWorkoutEffortScore"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEnvironmentalAudioExposure"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEnvironmentalSoundReduction"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeadphoneAudioExposure"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAtrialFibrillationBurden"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRate"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPeripheralPerfusionIndex"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRestingHeartRate"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierVo2Max"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingHeartRateAverage"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleWalkingSteadiness"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningGroundContactTime"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningStrideLength"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningVerticalOscillation"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierSixMinuteWalkTestDistance"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStairAscentSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStairDescentSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingDoubleSupportPercentage"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingSpeed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingStepLength"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryBiotin"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCaffeine"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCalcium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCarbohydrates"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryChloride"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCholesterol"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryChromium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCopper"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryEnergyConsumed"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatMonounsaturated"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatPolyunsaturated"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatSaturated"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatTotal"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFiber"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFolate"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryIodine"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryIron"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryMagnesium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryManganese"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryMolybdenum"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryNiacin"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPantothenicAcid"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPhosphorus"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPotassium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryProtein"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryRiboflavin"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySelenium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySodium"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySugar"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryThiamin"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminA"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminB12"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminB6"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminC"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminD"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminE"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminK"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryWater"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryZinc"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodAlcoholContent"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodPressureDiastolic"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodPressureSystolic"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierInsulinDelivery"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNumberOfAlcoholicBeverages"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNumberOfTimesFallen"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierTimeInDaylight"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierUvExposure"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWaterTemperature"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBasalBodyTemperature"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleSleepingBreathingDisturbances"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierForcedExpiratoryVolume1"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierForcedVitalCapacity"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierInhalerUsage"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierOxygenSaturation"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPeakExpiratoryFlowRate"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRespiratoryRate"),HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodGlucose")]
    }
}


extension HKWorkoutActivityType {
    static func name(for activityType: HKWorkoutActivityType) -> String {
        switch activityType.rawValue {
        case 1: return "American Football"
        case 2: return "Archery"
        case 3: return "Australian Football"
        case 4: return "Badminton"
        case 5: return "Baseball"
        case 6: return "Basketball"
        case 7: return "Bowling"
        case 8: return "Boxing"
        case 9: return "Climbing"
        case 10: return "Cricket"
        case 11: return "Cross Training"
        case 12: return "Curling"
        case 13: return "Cycling"
        case 14: return "Dance"
        case 15: return "Dance Inspired Training"
        case 16: return "Elliptical"
        case 17: return "Equestrian Sports"
        case 18: return "Fencing"
        case 19: return "Fishing"
        case 20: return "Functional Strength Training"
        case 21: return "Golf"
        case 22: return "Gymnastics"
        case 23: return "Handball"
        case 24: return "Hiking"
        case 25: return "Hockey"
        case 26: return "Hunting"
        case 27: return "Lacrosse"
        case 28: return "Martial Arts"
        case 29: return "Mind and Body"
        case 30: return "Mixed Metabolic Cardio Training"
        case 31: return "Paddle Sports"
        case 32: return "Play"
        case 33: return "Preparation and Recovery"
        case 34: return "Racquetball"
        case 35: return "Rowing"
        case 36: return "Rugby"
        case 37: return "Running"
        case 38: return "Sailing"
        case 39: return "Skating Sports"
        case 40: return "Snow Sports"
        case 41: return "Soccer"
        case 42: return "Softball"
        case 43: return "Squash"
        case 44: return "Stair Climbing"
        case 45: return "Surfing Sports"
        case 46: return "Swimming"
        case 47: return "Table Tennis"
        case 48: return "Tennis"
        case 49: return "Track and Field"
        case 50: return "Traditional Strength Training"
        case 51: return "Volleyball"
        case 52: return "Walking"
        case 53: return "Water Fitness"
        case 54: return "Water Polo"
        case 55: return "Water Sports"
        case 56: return "Wrestling"
        case 57: return "Yoga"
        case 58: return "Barre"
        case 59: return "Core Training"
        case 60: return "Cross Country Skiing"
        case 61: return "Downhill Skiing"
        case 62: return "Flexibility"
        case 63: return "High Intensity Interval Training"
        case 64: return "Jump Rope"
        case 65: return "Kickboxing"
        case 66: return "Pilates"
        case 67: return "Snowboarding"
        case 68: return "Stairs"
        case 69: return "Step Training"
        case 70: return "Wheelchair Walk Pace"
        case 71: return "Wheelchair Run Pace"
        case 72: return "Tai Chi"
        case 73: return "Mixed Cardio"
        case 74: return "Hand Cycling"
        case 75: return "Disc Sports"
        case 76: return "Fitness Gaming"
        case 77: return "Cardio Dance"
        case 78: return "Social Dance"
        case 79: return "Pickleball"
        case 80: return "Cooldown"
        case 82: return "Swim Bike Run"
        case 83: return "Transition"
        case 84: return "Underwater Diving"
        case 3000: return "Other"
        default: return "UNKNOWN"
        }
    }
}

struct TextFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.plainText]

    // by default our document is empty
    var text = ""
    var filename = ""

    // a simple initializer that creates new, empty documents
    init(initialText: String = "", ifilename: String = "") {
        text = initialText
        filename = ifilename
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        configuration.file.filename = filename
        configuration.file.preferredFilename = filename
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        configuration.existingFile?.filename = filename
        configuration.existingFile?.preferredFilename = filename
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

func togpxstring(idx: Int, _ sWorks: [SWork]) -> String {
    var gpxString = """
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
    var swok = sWorks[idx]
    swok.hrs = Array(swok.hrs?.reversed() ?? [])
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
   
    return gpxString
    
}

#Preview {
    StravaHealth()
}
