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
    
    @StateObject var locationViewModel = LocationViewModel()
    
    @State private var trainName = "All aboard"
    @ObservedObject var websocket = TrainWebsocket()
    
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "KaartTrain"
    )
    
    var body: some View {
        VStack {
            VStack {
                if locationViewModel.authorizationStatus == .notDetermined  {
                    Button(action: {
                        locationViewModel.requestPermission()
                    }, label: {
                        Label("Allow tracking", systemImage: "location")
                    })
                    .buttonStyle(.borderedProminent)
                }
                if trainName != "All aboard" {
                    Text(trainName)
                }
                Button {
                    websocket.receiveMessage()
                } label: {
                    Text("Reload")
                }.buttonStyle(.bordered)
            }.padding()
            Map(coordinateRegion: $locationViewModel.mapRegion, annotationItems: websocket.locations) { location in
                MapAnnotation(coordinate: location.middleCoordinatesMap) {
                    Image(systemName: "train.side.front.car")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            logger.log("Tapped on \(location.name, privacy: .public)")
                            Task {
                                let stops = await websocket.getStopsTrains(location.id)
                                self.trainName = "\(stops?.longName ?? "Trein") vanaf \(stops?.stations.first?.stationName ?? stops?.stations[0].stationName ?? "station-1") naar \(stops?.destination ?? "station-2")"
                            }
                            logger.log("Cords real \(location.coordinatesMap, privacy: .public)")
                            logger.log("mapRegion: \(mapRegion.center.longitude, privacy: .public)")
                        }
                }
                
            }.ignoresSafeArea(.container)
                .onAppear {
                    websocket.receiveMessage()
                }
                .onReceive(locationViewModel.$mapRegion) { newLocation in
                    websocket.updateBoundlocation(newLocation)
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



class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.63, longitude: 9.74), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        switch locationManager.authorizationStatus {
            //If we are authorized then we request location just once, to center the map
        case .authorizedWhenInUse:
            locationManager.requestLocation()
            // If we don´t, we request authorization
        default:
            print("Er is een ongehandel iets met de auth status van de locatie")
            break
        }
    }
    
    func requestPermission() {
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            locations.last.map {
                self.mapRegion = MKCoordinateRegion(
                    center: .init(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude),
                    span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2)
                )
            }
        }
    }
    
}
