//
//  TrainTrackWidgetBundle.swift
//  TrainTrackWidget
//
//  Created by Maarten Wittop Koning on 05/08/2023.
//

import WidgetKit
import SwiftUI

@main
struct TrainTrackWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrainTrackWidget()
        TrainTrackWidgetLiveActivity()
    }
}
