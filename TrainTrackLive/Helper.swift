//
//  Helper.swift
//  TrainTrackLive
//
//  Created by Olivier Wittop Koning on 30/07/2023.
//
import SwiftUI
import Foundation
// https://epsg.io/transform#s_srs=3857&t_srs=4326&x=1077825.0000000&y=5889230.0000000

// 1085169.112921 -> 9.744°

func epsg3857toEpsg4326(_ pos: [Float]) -> [Float] {
    var x = pos[0];
    var y = pos[1];
    x = (x * 180) / 20037508.34;
    /*y = (y * 180) / 20037508.34;
     y = (atan(exp(y * (Float(Float.pi / 180)))) * 360)
    y = (y / Float(Double.pi / 36)) - 90;*/
    y = y / (20037508.34 / 180);
    let exponent = (Float.pi / 180) * y;
    
    y = atan(pow(2.7182818284, exponent));
    y = y / (Float.pi / 360); // Here is the fixed line
    y = y - 90;
    return [x, y];
}

// 9.744° -> 1085169.112921

func epsg4326toEpsg3857(_ coordinates: [Float]) -> [Float] {
    var x: Float = 0.0;
    var y: Float = 0.0;
    x = (coordinates[1] * 20037508.34) / 180.0;
    y = log(tan(((90.0 + coordinates[0]) * Float.pi) / 360.0)) / (Float.pi / 180.0);
    y = Float((y * 20037508.34) / 180.0);
    return [x, y];
}
/*
 Berguen:
 1085169.112930621 = 9.74824°
 5882045.636828009 = 46.63097°
  
 
 Berguen bottom left:
 1075401.9408084194 = 9.6605
 5866728.345598243 = 46.5364°
 
 Berguen top right:
 1095724.4270476392 = 9.84306°
 5896720.681384878 = 46.72142°
 */

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

    var uurMinTekst: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.locale = Locale(identifier: "nl_NL")
        let formattedDate = dateFormatter.string(from: self)
        return formattedDate
    }
    
    var noon: Date {
        let gregorian = Calendar(identifier: .gregorian)
        var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())

        components.hour = 1
        components.minute = 0
        components.second = 0
        return gregorian.date(from: components)!
    }
    
    init(unix: Int) {
        self.init(timeIntervalSince1970: Double(unix))
    }
    var unix: Double {
        self.timeIntervalSince1970
    }
}

extension Double {
    var int: Int {
        return Int(self)
    }
}

extension TimeInterval {
    var difInSec: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .brief
        formatter.calendar?.locale = .current

        let formattedString = formatter.string(from: TimeInterval(self))!
        return formattedString
    }
    
    var difInHour: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .brief
        formatter.calendar?.locale = .current


        let formattedString = formatter.string(from: TimeInterval(self))!
        return formattedString
    }
}

extension String {
    var prettyJSON: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self.data(using: .utf8)!, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
    
}

extension Data {
    var prettyJSON: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}

let ALBULA_TUNNEL_PENDING = """
{"state":"PENDING","formation_id":null,"arrivalDelay":null,"arrivalTime":null,"aimedArrivalTime":null,"cancelled":false,"departureDelay":null,"departureTime":null,"aimedDepartureTime":null,"noDropOff":true,"noPickUp":true,"stationId":null,"stationName":"Albulatunnel","coordinate":[1092194,5872816],"platform":null},
"""
let ALBULA_TUNNEL_LEAVING = """
{"state":"LEAVING","formation_id":null,"arrivalDelay":null,"arrivalTime":null,"aimedArrivalTime":null,"cancelled":false,"departureDelay":null,"departureTime":null,"aimedDepartureTime":null,"noDropOff":true,"noPickUp":true,"stationId":null,"stationName":"Albulatunnel","coordinate":[1092194,5872816],"platform":null},
"""
