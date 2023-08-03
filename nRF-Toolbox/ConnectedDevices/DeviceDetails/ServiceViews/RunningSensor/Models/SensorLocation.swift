//
//  SensorLocation.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

enum SensorLocation: UInt8, CustomStringConvertible, CaseIterable {
    case other, topOfShoe, inShoe, hip, frontWheel, leftCrank, rightCrank, leftPedal, rightPedal, frontHub, rearDropout, chainstay, rearWheel, rearHub, chest, spider, chainRing

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
        }
    }
}
