//
//  BottomView.swift
//  TrackTrain
//
//  Created by Olivier Wittop Koning on 09/04/2024.
//

import SwiftUI
import MapKit

struct BottomView: View {
    var selectedRoute: LocationTrain?
    @Binding var visibleRegion: MKCoordinateRegion?
    @Binding var position: MapCameraPosition
    @ObservedObject var websocket: TrainWebsocket
    
    var body: some View {
        VStack {
            if selectedRoute?.stops != nil {
                Text("\(selectedRoute?.name ?? "No train name") from \(selectedRoute?.stops?.stations[0].stationName ?? "waiting") arriving at \(getArriTime(selectedRoute?.stops?.stations.last?.arrivalTime ?? 1000)) in \(selectedRoute?.stops?.destination ?? "waiting")")
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
                    }
                }
                Spacer()
            }.background(.thinMaterial)
        }
    }
}
