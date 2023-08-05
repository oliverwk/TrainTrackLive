//
//  ContentView.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//

import SwiftUI
import os

struct ContentView: View {
    let logger = Logger(
        subsystem: "nl.wittopkoning.traintrack",
        category: "ContentView"
    )
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
                
                NavigationLink("Go go to trains") {
                    KaartTrain()
                }.padding(9)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(7)
                NavigationLink("Depatures Bergün") {
                    DepartureBoardTrack()
                }.padding(9)
                    .background(.green)
                    .foregroundStyle(.white)
                    .cornerRadius(7)
            }
        }
    }
}

// https://developers.auravant.com/en/blog/2022/09/09/post-3/


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
