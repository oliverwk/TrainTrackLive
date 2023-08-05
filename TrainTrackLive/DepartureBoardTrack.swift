//
//  DepartureBoardTrack.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 05/08/2023.
//

import SwiftUI

// Hier een vertrek en aankomst bord laten zien in een list
// en dan een functie toevoegen dat je die kan tracken met een live-activity

// het id van berugen is 8509197

struct DepartureBoardTrack: View {
    var body: some View {
        Text("Hello, World!")
        List {
            ForEach(1...10, id: \.self) { section in
                Text("\(section)")
            }
        }
    }
}

struct DepartureBoardTrack_Previews: PreviewProvider {
    static var previews: some View {
        DepartureBoardTrack()
    }
}
