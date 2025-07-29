//
//  RSCSSensorLocation.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 29/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: SensorLocation
    
public enum RSCSSensorLocation: UInt8, CustomStringConvertible, CaseIterable {
    case other, topOfShoe, inShoe, hip, frontWheel, leftCrank, rightCrank, leftPedal, rightPedal, frontHub, rearDropout, chainstay, rearWheel, rearHub, chest, spider, chainRing

    public var description: String {
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
