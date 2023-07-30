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
                
                NavigationLink("Go Go train") {
                    KaartTrain()
                }
                NavigationLink {
                    KaartTrain()
                } label: {
                    Button(action: {}, label: {
                        Text("Go to trains")
                    })
                    .buttonStyle(.borderedProminent)
                }
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
