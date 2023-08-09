//
//  TrainTrackWidgetLiveActivity.swift
//  TrainTrackWidget
//
//  Created by Maarten Wittop Koning on 05/08/2023.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TrainTrackWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var fracBegin: Double
        var CurrentORArrivingStation: String
        var delay: Int?
        var eindSpoor: String
        var aankomstTijd: Date
        var vertrekTijd: Date
        var currentTijd: Date
        var tijdCurrentSpenderen: TimeInterval
    }
    
    // Fixed non-changing properties about your activity go here!
    var StartStationName: String
    var EndStationName: String
    var TrainName: String
}

struct TrainTrackWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainTrackWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                VStack {
                    HStack {
                        Text("\(context.attributes.TrainName)").foregroundColor(.black)
                        Spacer()
                        if context.state.tijdCurrentSpenderen > 0 {
                            Text("\(context.state.tijdCurrentSpenderen.difInHour) min hier").foregroundColor(.blue).foregroundColor(.black)
                        } else {
                            Text("\((context.state.aankomstTijd.timeIntervalSince1970-Date.now.timeIntervalSince1970).difInHour)").foregroundColor(.black)
                        }
                       
                        Spacer()
                        Text("    \(context.state.eindSpoor)").foregroundColor(.black)
                    }.padding(.bottom, 5)
                    HStack {
                        Text("\(context.attributes.StartStationName.contains("/") ? String(context.attributes.StartStationName.split(separator: "/")[0]) : context.attributes.StartStationName)").fontWeight(.heavy).font(.body).foregroundColor(.black)
                        Text(" \(context.state.vertrekTijd.uurMinTekst)")
                            .fontWeight(.heavy)
                            .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                            .font(.body)
                        Spacer()
                        Text("\(context.state.aankomstTijd.uurMinTekst) ")
                            .fontWeight(.heavy)
                            .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                            .font(.body)
                        Text("\(context.attributes.EndStationName)").fontWeight(.heavy).font(.body).foregroundColor(.black)
                    }
                }
                
                GeometryReader { geometry in
                    HStack {
                        ZStack(alignment: .leading) {
                            Rectangle().frame(width: geometry.size.width , height: 15)
                                .opacity(0.4)
                                .foregroundColor(.green)
                                .cornerRadius(45.0)
                            withAnimation {
                                Rectangle().frame(width: min(CGFloat(context.state.fracBegin)*geometry.size.width, geometry.size.width), height: 15)
                                    .foregroundColor(.green)
                            }.cornerRadius(45.0)
                            
                            Circle()
                                .frame(width: 20, height: 20)
                                .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                                .position(CGPoint(x: CGFloat(context.state.fracBegin)*geometry.size.width, y: 7))
                        }
                    }
                }
                
                HStack {
                    Text((context.state.delay ?? 0) > 0 ? "delayed" : "on time")
                        .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                        .font(.callout)
                    Spacer()
                    Text("\(context.state.currentTijd.uurMinTekst) ")
                        .fontWeight(.heavy)
                        .foregroundColor((context.state.delay ?? 0) > 0 ? Color.orange : Color.green)
                        .font(.headline)
                    Text("\(context.state.CurrentORArrivingStation)")
                        .fontWeight(.heavy)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    if context.state.delay ?? 0 > 0 {
                        Text("+\(context.state.delay ?? 0)m")
                            .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                            .font(.callout)
                    } else {
                        Text("           ")
                    }
                  
                }
            }.padding()
                .activityBackgroundTint(.white)
                .activitySystemActionForegroundColor(.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("+\(context.state.delay ?? 0)m")
                        .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                        .font(.callout)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.aankomstTijd.uurMinTekst) ")
                        .fontWeight(.heavy)
                        .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                        .font(.body)
                    Text("\(context.attributes.EndStationName)").fontWeight(.heavy).font(.body).foregroundColor(.black)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    GeometryReader { geometry in
                        HStack {
                            ZStack(alignment: .leading) {
                                Rectangle().frame(width: geometry.size.width , height: 15)
                                    .opacity(0.4)
                                    .foregroundColor(.green)
                                    .cornerRadius(45.0)
                                withAnimation {
                                    Rectangle().frame(width: min(CGFloat(context.state.fracBegin)*geometry.size.width, geometry.size.width), height: 15)
                                        .foregroundColor(.green)
                                }.cornerRadius(45.0)
                                
                                Circle()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
                                    .position(CGPoint(x: CGFloat(context.state.fracBegin)*geometry.size.width, y: 7))
                            }
                        }
                    }
                }
            } compactLeading: {
                Text("\(context.attributes.EndStationName)").foregroundColor(.red).padding(.leading)
            } compactTrailing: {
                Text("+\(context.state.delay ?? 0)").foregroundColor(context.state.delay == 0 ? .green : .orange)
            } minimal: {
                ZStack {
                            Circle()
                                .stroke(
                                    (context.state.delay == 0 ? Color.green : Color.orange).opacity(0.5),
                                    lineWidth: 3
                                )
                                .frame(width: 25, height: 25)
                    
                            Circle()
                                .trim(from: 0, to: CGFloat(context.state.fracBegin))
                                .stroke(
                                    context.state.delay == 0 ? .green : .orange,
                                    lineWidth: 3
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 25, height: 25)

                }
            }
            .widgetURL(URL(string: "https://www.apple.com"))
            .keylineTint((context.state.delay ?? 0) > 0 ? Color.red : Color.green)
        }
    }
}

struct TrainTrackWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = TrainTrackWidgetAttributes(StartStationName: "Berguen", EndStationName: "St. Moritzz", TrainName: "IR 6745")
    static let contentState = TrainTrackWidgetAttributes.ContentState(fracBegin: 0.8, CurrentORArrivingStation: "Preda", delay: 3, eindSpoor: "Pl. 2A", aankomstTijd: Date(timeIntervalSince1970: Date.now.timeIntervalSince1970-1300), vertrekTijd: Date(timeIntervalSince1970: Date.now.timeIntervalSince1970+1500), currentTijd: Date.now, tijdCurrentSpenderen: 0.0)
    
    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
    }
}
