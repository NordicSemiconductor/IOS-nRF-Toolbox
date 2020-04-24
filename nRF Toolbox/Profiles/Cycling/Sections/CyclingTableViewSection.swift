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
    var isHidden: Bool = false
    
    var wheelSize: Double = 0.6
    private var wheelCircumference: Double {
        self.wheelSize * .pi
    }
    
    private var oldCharacteristic: CyclingCharacteristic = .zero
    
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
        DefaultDetailsTableViewCellModel(title: "Gear Ratio", identifier: .gearRatio)
    ]
    
    func registerCells(_ tableView: UITableView) {
        tableView.registerCellClass(cell: DetailsTableViewCell.self)
        tableView.registerCellNib(cell: SliderTableViewCell.self)
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let detailsCell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
        detailsCell.update(with: items[index])
        return detailsCell
    }
    
    mutating func reset() {
        for i in items.enumerated() {
            items[i.offset].details = "-"
        }
        
        oldCharacteristic = .zero 
        totalTravelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
        travelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
        speed = Measurement<UnitSpeed>(value: 0, unit: .milesPerHour)
        gearRatio = 0
        cadence = 0
    }
    
    var numberOfItems: Int { return items.count }
    
    let sectionTitle: String = "Speed and Cadence"
    
    var id: Identifier<Section> = .cycling
    
    private func update(_ item: DefaultDetailsTableViewCellModel) -> DefaultDetailsTableViewCellModel {
        var item = item
        
        let speedFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 1)
        let distanceFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 2)
        
        switch item.identifier {
        case .speed:
            item.details = speedFormatter.string(from: speed)
        case .distance:
            item.details = distanceFormatter.string(from: travelDistance)
        case .totalDistance:
            item.details = distanceFormatter.string(from: totalTravelDistance)
        case .cadence:
            item.details = "\(cadence) RPM"
        case .gearRatio:
            item.details = String(format: "%.2f", gearRatio)
        default:
            break
        }
        return item
    }
    
    mutating func update(with data: Data) {
        
        let characteristic = CyclingCharacteristic(data: data)
        
        characteristic.travelDistance(with: wheelCircumference)
            .flatMap { self.totalTravelDistance = $0 }
        characteristic.distance(oldCharacteristic, wheelCircumference: wheelCircumference)
            .flatMap { self.travelDistance = self.travelDistance + $0 }
        characteristic.gearRatio(oldCharacteristic)
            .flatMap { self.gearRatio = $0 }
        characteristic.speed(oldCharacteristic, wheelCircumference: wheelCircumference)
            .flatMap { self.speed = $0 }
        characteristic.cadence(oldCharacteristic)
            .flatMap { self.cadence = $0 }
        
        oldCharacteristic = characteristic
        
        items = items.map(self.update)
    }
}
