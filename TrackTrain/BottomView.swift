//
//  BottomView.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 09/04/2024.
//

import SwiftUI
import MapKit

struct BottomView: View {
    @Binding var selectedTrajectory: [CLLocationCoordinate2D]?
    @Binding var selectedRoute: LocationTrain?
    @Binding var selectedStops: TrainStopContent?
    @Binding var visibleRegion: MKCoordinateRegion?
    @Binding var position: MapCameraPosition
    @Binding var selectedItem: String?
    @ObservedObject var websocket: TrainWebsocket
    
    var body: some View {
        VStack {
            if selectedRoute != nil {
                Text("\(selectedRoute?.name ?? "No train name") from \(selectedStops?.stations[0].stationName ?? "waiting") arriving at \(getArriTime(selectedStops?.stations.last?.arrivalTime ?? 1000)) in \(selectedStops?.destination ?? "waiting")")
                        .padding(10)
                        .background(.thinMaterial)
                        .tint(.blue)
                        .cornerRadius(5)
                        .padding(5)
            }
            HStack {
                Spacer()
                VStack(spacing:0) {
                    HStack {
                        Button("", systemImage: "timelapse") {
                            websocket.connect(visibleRegion!)
                        }.padding(.top)
                        Button("", systemImage: "location") {
                            let LM = LocationModel()
                            LM.requestPermission()
                            position = .userLocation(fallback: .automatic)
                        }.padding(.top)
                        Button("Re") {
                            let trainIndex = websocket.locations.firstIndex(where: {$0.id == selectedItem})
                            print("index\(String(describing: trainIndex)) locations.id: \(websocket.locations[trainIndex!].id)  and selectedRoute.id: \(String(describing: selectedRoute?.id))")
                            print("index\(String(describing: trainIndex)) locations.stop: \(String(describing: websocket.locations[trainIndex!].stops)) and selectedRoute.stops: \(String(describing: selectedRoute?.stops))")
                            print("selectedRoute.stops:", selectedRoute?.stops ?? "nil")
                            print("selectedRoute.trajectory: \(selectedRoute?.trajectory.count ?? 999) or \(selectedRoute?.trajectoryExpanded.count ?? 999)")
                            selectedStops = websocket.locations[trainIndex!].stops
                            selectedTrajectory = websocket.locations[trainIndex!].trajectory
                            selectedRoute?.name = websocket.locations[trainIndex!].name
                            print("selectedTrajectory: \(selectedTrajectory?.count ?? 999)")
                            print("websocket.locations[trainIndex!].trajectory: \(websocket.locations[trainIndex!].trajectory.count) or \(websocket.locations[trainIndex!].trajectoryExpanded.count)")
                        }.padding(.top)
                    }
                }
                Spacer()
            }.background(.thinMaterial)
        }
    }
}
