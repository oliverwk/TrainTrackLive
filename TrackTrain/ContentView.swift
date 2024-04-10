//
//  ContentView.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 06/04/2024.
//

import SwiftUI
import MapKit
import os

struct ContentView: View {
    let logger = Logger(
        subsystem: "nl.wittopkoning.tracktrain",
        category: "ContentView"
    )
    let routeLine = [coordinate(46.675262, 9.682276), coordinate(46.675446, 9.6896515), coordinate(46.67238, 9.693523), coordinate(46.6734, 9.694843), coordinate(46.676285, 9.694492), coordinate(46.67653, 9.6924), coordinate(46.675354, 9.691699), coordinate(46.6725, 9.694502), coordinate(46.664932, 9.697799), coordinate(46.66098, 9.703108), coordinate(46.65428, 9.721137), coordinate(46.64917, 9.7239485), coordinate(46.642914, 9.735062), coordinate(46.64055, 9.734674), coordinate(46.63707, 9.737226), coordinate(46.636063, 9.740693), coordinate(46.629684, 9.750251), coordinate(46.626297, 9.752821), coordinate(46.62445, 9.751806), coordinate(46.6203, 9.753062), coordinate(46.621048, 9.755381), coordinate(46.623764, 9.753781), coordinate(46.6252, 9.756809), coordinate(46.6288, 9.755632), coordinate(46.62883, 9.758588), coordinate(46.623383, 9.757869), coordinate(46.620758, 9.754913), coordinate(46.61786, 9.761867), coordinate(46.614563, 9.762136), coordinate(46.60295, 9.755722), coordinate(46.601837, 9.752416), coordinate(46.603333, 9.750574), coordinate(46.604538, 9.751886), coordinate(46.60414, 9.753781), coordinate(46.601288, 9.753917), coordinate(46.599014, 9.758067), coordinate(46.596436, 9.758444), coordinate(46.59642, 9.761273), coordinate(46.59787, 9.76184), coordinate(46.59816, 9.759405), coordinate(46.594223, 9.75707), coordinate(46.59439, 9.760133), coordinate(46.596786, 9.762971), coordinate(46.598114, 9.762029), coordinate(46.596786, 9.759791), coordinate(46.592743, 9.762226), coordinate(46.591415, 9.766133), coordinate(46.590942, 9.773006), coordinate(46.587692, 9.778351), coordinate(46.55876, 9.848078), coordinate(46.555374, 9.859801), coordinate(46.5549, 9.865963), coordinate(46.55179, 9.873833), coordinate(46.551544, 9.888628), coordinate(46.54698, 9.886948), coordinate(46.53392, 9.873617)]

    let bergun = Town(id: "29339230", name: "Bergün", coordinates: [46.631158, 9.746958])
    let preda = Town(id: "29309230", name: "Preda", coordinates: [46.588862, 9.775371])
    
    @State private var LocationsTrians: [LocationTrain] = [
        LocationTrain(id: "RHBRE87667", name: "RHB RE87667", colour: .blue, from: Town(id: "29339230", name: "Bergün", coordinates: [46.631158, 9.746958]), to: Town(id: "29309230", name: "Preda", coordinates: [46.588862, 9.775371]),
                      coordinates: [[46.606828, 9.755901]], timeIntervals: [[9,5]], type: .rail),
        
        LocationTrain(id: "RHBRE87668", name: "RHB RE87668", colour: .blue, from: Town(id: "29339230", name: "Bergün", coordinates: [46.620553, 9.752464]), to: Town(id: "29309230", name: "Preda", coordinates: [46.588862, 9.775371]), coordinates: [[46.624910, 9.751958]], timeIntervals: [[9,5]], type: .rail), 
    ]
    
    let locationsStation: [Town] = [Town(id: "RHBBERGUN", name: "RHB Berguen", coordinates: [46.631158, 9.746958])]
    @ObservedObject var websocket = TrainWebsocket()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedItem: String?
    @State private var selectedRoute: LocationTrain?
    
    
    var body: some View {
        Map(position: $position, selection: $selectedItem) {

            ForEach(websocket.locations) { train in
                Marker("\(train.name) with type: \(train.type)", systemImage: train.type == .bus ? "bus.fill" : "train.side.front.car", coordinate: coordinate(train.currentCoordinates))
                    .tint(.blue)
                    .tag(train.id)
            }
            
            if (selectedRoute != nil || locationsStation[0].id != "") { // TODO: maak dit alleen stations die op de route die geslecteerd is liggen
                ForEach(locationsStation) { locationStation in
                    Annotation(locationStation.name, coordinate: locationStation.coordinatesSwiftUI) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.background)
                            Image(systemName: "homekit")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding(5)
                        }
                    }.tag(locationStation.name)
                        .annotationTitles(.hidden)
                }
            }
            
            if (selectedRoute != nil) {
                MapPolyline(coordinates: selectedRoute?.trajectory ?? routeLine, contourStyle: .geodesic)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            
            UserAnnotation()
        }.safeAreaInset(edge: .bottom, content: {
            BottomView(selectedRoute: selectedRoute, visibleRegion: $visibleRegion, position: $position, websocket: websocket)
        })
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: selectedItem ?? "nothing", { _, trainSelected in
            print("Selected train \(trainSelected)")
            selectedRoute = getTrain(websocket.locations, trainSelected)
            Task {
                let stops = await websocket.getStopsTrains(trainSelected)
                print("destination: \(String(describing: stops?.destination))")
                selectedRoute?.stops = stops
            }
            position = .automatic
        })
        .onAppear {
            position = .userLocation(fallback: .automatic)
        }
        .onMapCameraChange { context in
            visibleRegion = context.region
            // Ask for a new websocket connection if this region is outside the current region.
            //websocket.connect(visibleRegion!)
        }
    }
}

#Preview {
    ContentView()
}
