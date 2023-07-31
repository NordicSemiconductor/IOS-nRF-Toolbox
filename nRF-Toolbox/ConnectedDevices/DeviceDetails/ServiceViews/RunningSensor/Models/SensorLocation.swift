//
//  SensorLocation.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

enum SensorLocation: CustomStringConvertible {
    case other, topOfShoe, inShoe, hip, frontWheel, leftCrank, rightCrank, leftPedal, rightPedal, frontHub, rearDropout, chainstay, rearWheel, rearHub, chest, spider, chainRing, unknown

    init(data: Data) {
        guard data.count == 1 else {
            self = .unknown
            return
        }
        switch data[0] {
        case 0: self = .other
        case 1: self = .topOfShoe
        case 2: self = .inShoe
        case 3: self = .hip
        case 4: self = .frontWheel
        case 5: self = .leftCrank
        case 6: self = .rightCrank
        case 7: self = .leftPedal
        case 8: self = .rightPedal
        case 9: self = .frontHub
        case 10: self = .rearDropout
        case 11: self = .chainstay
        case 12: self = .rearWheel
        case 13: self = .rearHub
        case 14: self = .chest
        case 15: self = .spider
        case 16: self = .chainRing
        default: self = .unknown
        }
    }

    var description: String {
        switch self {
        case .other: return "Other"
        case .topOfShoe: return "Top of shoe"
        case .inShoe: return "In shoe"
        case .hip: return "Hip"
        case .frontWheel: return "Front wheel"
        case .leftCrank: return "Left crank"
        case .rightCrank: return "Right crank"
        case .leftPedal: return "Left pedal"
        case .rightPedal: return "Right pedal"
        case .frontHub: return "Front hub"
        case .rearDropout: return "Rear dropout"
        case .chainstay: return "Chainstay"
        case .rearWheel: return "Rear wheel"
        case .rearHub: return "Rear hub"
        case .chest: return "Chest"
        case .spider: return "Spider"
        case .chainRing: return "Chain ring"
        case .unknown: return "Unknown"
        }
    }
}
