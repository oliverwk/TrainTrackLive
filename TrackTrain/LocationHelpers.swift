//
//  LocationHelpers.swift
//  TrackTrain
//
//  Created by Olivier  Wittop Koning on 06/04/2024.
//

import Foundation
import MapKit

class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
            //If we are authorized then we request location just once, to center the map
        case .authorizedWhenInUse:
            print("We have location")
            // If we don´t, we request authorization
        case .notDetermined:
            print("We haven't have asked for location")
        case .denied:
            print("We have been denied location")
            // If we don´t, we request authorization
        default:
            print("Something gone wrong with location")
            break
        }
    }
    
    func requestPermission() {
        switch locationManager.authorizationStatus {
            //If we are authorized then we request location just once, to center the map
        case .authorizedWhenInUse:
            print("We have location")
            // If we don´t, we request authorization
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .denied:
            print("We have been denied location")
            // If we don´t, we request authorization
        default:
            print("Something gone wrong with location")
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch locationManager.authorizationStatus {
            //If we are authorized then we request location just once, to center the map
        case .authorizedWhenInUse:
            print("We have location")
            // If we don´t, we request authorization
        case .notDetermined:
            print("We haven't have asked for location")
        case .denied:
            print("We have been denied location")
            // If we don´t, we request authorization
        default:
            print("Something gone wrong with location")
            break
        }
    }
    
}
