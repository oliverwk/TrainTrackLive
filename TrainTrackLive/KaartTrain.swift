//
//  KaartTrain.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//

import SwiftUI
import MapKit
import os

struct KaartTrain: View {
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.63, longitude: 9.74), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    @State private var trainName = "All aboard"
    @ObservedObject var websocket = TrainWebsocket()
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "KaartTrain"
    )
    
    var body: some View {
        VStack {
            VStack {
                if trainName != "All aboard" {
                    Text(trainName)
                }
                Button {
                    websocket.receiveMessage()
                } label: {
                    Text("Reload")
                }.buttonStyle(.bordered)
            }.padding()
            Map(coordinateRegion: $mapRegion, annotationItems: websocket.locations) { location in
                MapAnnotation(coordinate: location.middleCoordinatesMap) {
                    Circle()
                        .stroke(.red, lineWidth: 5)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            Task {
                                let stops = await websocket.getStopsTrains(location.id)
                                self.trainName = "\(stops?.longName ?? "Trein") from \(stops?.stations.first?.stationName ?? stops?.stations[0].stationName ?? "station-1") to \(stops?.destination ?? "station-2")"
                            }
                            logger.log("Tapped on \(location.name, privacy: .public)")
                            logger.log("Cords real \(location.coordinatesMap, privacy: .public)")
                            logger.log("mapRegion: \(mapRegion.center.longitude, privacy: .public)")
                        }
                }
                
            }.ignoresSafeArea(.container)
                .onAppear {
                    websocket.receiveMessage()
                }
        }
    }
}


struct KaartTrian_Previews: PreviewProvider {
    static var previews: some View {
        KaartTrain()
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("KaartTrain Preview")
    }
}

// https://developers.auravant.com/en/blog/2022/09/09/post-3/


