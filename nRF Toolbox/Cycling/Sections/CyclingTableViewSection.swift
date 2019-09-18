//
//  CyclingTableViewSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

extension Identifier where Value == DetailsTableViewCellModel {
    static let speed = Identifier<Value>.init(string: "SpeedIdentifier")
    static let cadence = Identifier<Value>.init(string: "CadenceIdentifier")
    static let distance = Identifier<Value>.init(string: "DistanceIdentifier")
    static let totalDistance = Identifier<Value>.init(string: "TotalDistanceIdentifier")
    static let gearRatio = Identifier<Value>.init(string: "GearRationIdentifier")
}

struct CyclingTableViewSection: Section {
    private let wheelRevolutionFlag: UInt8 = 0x01
    private let crankRevolutionFlag: UInt8 = 0x02
    private let wheelCircumference: Double = 2.6//UserDefaults.standard.double(forKey: "key_diameter")
    
    private var oldWheelRevolution: Int = 0
    private var oldCrankRevolution: Int = 0
    private var oldWheelEventTime: Double = 0
    private var oldCrankEventTime: Double = 0
    
    private var travelDistance = Measurement<UnitLength>(value: 0, unit: .kilometers)
    private var totalTravelDistance = Measurement<UnitLength>(value: 0, unit: .kilometers)
    private var speed = Measurement<UnitSpeed>(value: 0, unit: .kilometersPerHour)
    private var gearRatio: Double = 1
    private var cadence: Int = 0
    
    var items: [DefaultDetailsTableViewCellModel] = [
        DefaultDetailsTableViewCellModel(title: "Speed", identifier: .speed),
        DefaultDetailsTableViewCellModel(title: "Cadence", identifier: .cadence),
        DefaultDetailsTableViewCellModel(title: "Distance", identifier: .distance),
        DefaultDetailsTableViewCellModel(title: "Total Distance", identifier: .totalDistance),
        DefaultDetailsTableViewCellModel(title: "Gear Retio", identifier: .gearRatio)
    ]
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let detailsCell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
        detailsCell.update(with: items[index])
        return detailsCell
    }
    
    var numberOfItems: Int { return items.count }
    
    let sectionTitle: String = "Speed and Cadence"
    
    var id: Identifier<Section> = "cycling"
    
    private func update(_ item: DefaultDetailsTableViewCellModel) -> DefaultDetailsTableViewCellModel {
        var item = item
        let measurementFormatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        measurementFormatter.numberFormatter = numberFormatter
        
        switch item.identifier {
        case .speed:
            item.value = measurementFormatter.string(from: speed)
        case .distance:
            item.value = measurementFormatter.string(from: travelDistance)
        case .totalDistance:
            item.value = measurementFormatter.string(from: totalTravelDistance)
        case .cadence:
            item.value = "\(cadence) RPM"
        case .gearRatio:
            item.value = String(format: "%.2f", gearRatio)
        default:
            break
        }
        return item
    }
    
    mutating func update(with data: Data) {
        let value = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))
        
        let flag = value[0]
        
        var wheelRevDiff: Double = 0
        var crankRevDiff: Double = 0
        
        if flag & wheelRevolutionFlag == 1 {
            wheelRevDiff = self.processWheelData(value)
            if flag & 0x02 == 2 {
                crankRevDiff = self.processCrankData(value, revolutionIndex: 7)
                if crankRevDiff > 0 {
                    gearRatio = wheelRevDiff / crankRevDiff
                }
            }
        } else if flag & crankRevolutionFlag == 2 {
            crankRevDiff = self.processCrankData(value, revolutionIndex: 1)
            if crankRevDiff > 0 {
                gearRatio = wheelRevDiff / crankRevDiff
            }
        }
        
        items = items.map(self.update)
    }
    
    private mutating func processWheelData(_ value: UnsafeMutablePointer<UInt8>) -> Double {
        let wheelRevolution = UInt8(CFSwapInt32LittleToHost(UInt32(value[1])))
        let wheelEventTime  = Double((UInt16(value[6]) * 0xFF) + UInt16(value[5]))
        
        var wheelRevolutionDiff: Double = 0
        var wheelEventTimeDiff: Double = 0
        if oldWheelRevolution != 0, wheelRevolution > oldWheelRevolution {
            wheelRevolutionDiff = Double(wheelRevolution) - Double(oldWheelRevolution)
            
            travelDistance = travelDistance + Measurement<UnitLength>(value: (wheelRevolutionDiff * wheelCircumference), unit: .meters)
            totalTravelDistance = Measurement<UnitLength>(value: Double(wheelRevolution) * Double(wheelCircumference), unit: .meters)
        }
        
        if oldWheelEventTime != 0 {
            wheelEventTimeDiff = wheelEventTime - oldWheelEventTime
        }
        if wheelEventTimeDiff > 0 {
            wheelEventTimeDiff = wheelEventTimeDiff / 1024.0
            speed = Measurement<UnitSpeed>.init(value: ((wheelRevolutionDiff * wheelCircumference) / wheelEventTimeDiff), unit: .milesPerHour)
        }
        
        oldWheelRevolution = Int(wheelRevolution)
        oldWheelEventTime = Double((UInt16(value[6]) * 0xFF) + UInt16(value[5]))
        
        return wheelRevolutionDiff
    }
    
    private mutating func processCrankData(_ value: UnsafeMutablePointer<UInt8>, revolutionIndex index : Int) -> Double {
        let crankRevolution = Int(CFSwapInt16LittleToHost(UInt16(value[index])))
        let crankEventTime  = Double((UInt16(value[index+3]) * 0xFF) + UInt16(value[index+2]))+1.0
        var crankEventTimeDiff: Double = 0
        var crankRevolutionDiff: Double = 0
        
        if oldCrankEventTime != 0 {
            crankEventTimeDiff = crankEventTime - oldCrankEventTime
        }
        
        if oldCrankRevolution != 0 {
            crankRevolutionDiff = Double(crankRevolution - oldCrankRevolution)
        }
        
        if crankEventTimeDiff > 0 {
            crankEventTimeDiff = crankEventTimeDiff / 1024.0
            cadence = Int(Double(crankRevolutionDiff / crankEventTimeDiff) * Double(60))
        }
        
        oldCrankRevolution = crankRevolution
        oldCrankEventTime = crankEventTime
        
        return crankRevolutionDiff
    }
    
}
