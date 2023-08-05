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
            HStack {
                Image(systemName: "train.side.front.car")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text(trainName)
                Button {
                    websocket.receiveMessage()
                } label: {
                    Text("Reload")
                }
            }.padding()
            Map(coordinateRegion: $mapRegion, annotationItems: websocket.locations) { location in
                MapAnnotation(coordinate: location.middleCoordinatesMap) {
                    Circle()
                       // .stroke(location.name.contains("train") ? .red : .blue, lineWidth: 5)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            self.trainName = location.name
                            logger.log("Tapped on \(location.name, privacy: .public)")
                            logger.log("Cords real \(location.coordinatesMap, privacy: .public)")
                            logger.log("mapRegion: \(mapRegion.center.longitude, privacy: .public)")
                        }
                }
                
            }.ignoresSafeArea(.container)
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


