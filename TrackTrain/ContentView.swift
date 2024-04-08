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
    @State private var LocationsTrians: [LocationTrain] = [
        LocationTrain(id: "RHBRE87667", name: "RHB RE87667", colour: .blue, coordinates: [[46.606828, 9.755901]], timeIntervals: [[9,5]]),
        LocationTrain(id: "RHBRERE87687", name: "RHB RE87687", colour: .blue, coordinates: [[46.620553, 9.752464]], timeIntervals: [[9,5]])
    ]
    let locationsStation: [LocationTrain] = [LocationTrain(id: "RHBBERGUN", name: "RHB Berguen", colour: .red, coordinates: [[46.631158, 9.746958]], timeIntervals: [[9,5]])]
    
    @State private var position: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedItem: String?
    @State private var selectedRoute: LocationTrain?
    
    
    var body: some View {
        Map(position: $position, selection: $selectedItem) {
            Annotation(locationsStation[0].name, coordinate: locationsStation[0].coordinatesSwiftui) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.background)
                    Image(systemName: "homekit")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(5)
                }
            }.tag(locationsStation[0].name)
            .annotationTitles(.hidden)
            
            ForEach(LocationsTrians) { train in
                Marker(train.name, systemImage: "train.side.front.car", coordinate: train.coordinatesSwiftui)
                    .tint(.blue)
                    .tag(train.id)
            }
            
        }.safeAreaInset(edge: .bottom, content: {
            HStack {
                HStack {
                    Spacer()
                    VStack(spacing:0) {
                        if let selectedRoute {
                            Text("You have selected a train \(selectedRoute.)")
                        }
                        HStack {
                            Button("Change trains", systemImage: "timelapse") {
                                LocationsTrians[0].coordinates = [[46.612331, 9.760316]]
                                LocationsTrians[1].coordinates = [[46.623005, 9.753640]]
                                position = .automatic
                            }.padding(.top)
                            Button("", systemImage: "location") {
                                let LM = LocationModel()
                                LM.requestPermission()
                                position = .userLocation(fallback: .automatic)
                            }.padding(.top)
                        }
                    }
                    Spacer()
                }.background(.thinMaterial)
            }
        })
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: selectedItem ?? "nothing", { oldValue, newValue in
            print("Selected train \(newValue)")
            selectedRoute = getTrain(LocationsTrians, selectedItem ?? "nothing")
        })
        .onAppear(perform: {
            position = .userLocation(fallback: .automatic)
            // position = .automatic // This is for when all markers are shown
            // TODO: connect to a websocket here
        })
        .onMapCameraChange { context in
            visibleRegion = context.region
            // Ask for a new websocket connection if this region is outside the current region.
        }
    }
}

#Preview {
    ContentView()
}
