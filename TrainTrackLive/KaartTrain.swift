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
    
    @ObservedObject var websocket = TrainWebsocket()
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "KaartTrain"
    )
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Button {
                    websocket.receiveMessage()
                } label: {
                    Text("Reload")
                }
            }.padding()
            Map(coordinateRegion: $mapRegion, annotationItems: websocket.locations) { location in
                MapAnnotation(coordinate: location.middleCoordinatesMap) {
                    Circle()
                        .stroke(.red, lineWidth: 5)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            print("Tapped on \(location.name)")
                            print("Cords real \(location.coordinatesMap)")
                            print("mapRegion: \(mapRegion.center.longitude)")
                        }
                }
                
            }.cornerRadius(10.0, antialiased: true)
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


