//
//  WheelSizeSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 24.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class WheelSizeSection: Section {

    private let wheelSizeKey = "wheel_size"
    private (set) var wheelSize: Measurement<UnitLength>

    init() {
        if let data = UserDefaults.standard.value(forKey: wheelSizeKey) as? Data,
           let size = try? PropertyListDecoder().decode(Measurement<UnitLength>.self, from: data) {
            self.wheelSize = size
        } else {
            self.wheelSize = Measurement<UnitLength>(value: 600, unit: .millimeters)
        }
    }

    var wheelSizeChangedAction: ((Measurement<UnitLength>) -> ())?

    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: SliderTableViewCell.self)

        let units: UnitLength = .inches

        cell.slider.minimumValue = 20
        cell.slider.maximumValue = 29

        let unitFormatter = MeasurementFormatter()
        unitFormatter.numberFormatter = .zeroDecimal
        unitFormatter.unitOptions = .providedUnit

        cell.action = { value in
            self.wheelSize = Measurement<UnitLength>(value: value, unit: units)
            let data = try? PropertyListEncoder().encode(self.wheelSize)
            UserDefaults.standard.set(data, forKey: self.wheelSizeKey)
        }

        cell.slider.value = Float(wheelSize.converted(to: units).value)

        let inchStr = unitFormatter.string(from: wheelSize.converted(to: .inches))
        let mmStr = unitFormatter.string(from: wheelSize.converted(to: .millimeters))
        cell.title.text = "\(inchStr) / \(mmStr)"

        return cell
    }

    func reset() {  }

    private(set) var numberOfItems: Int = 1
    private(set) var sectionTitle: String = "Wheel Size"
    private(set) var id: Identifier<Section> = "WheelSizeSection"
    private(set) var isHidden: Bool = false

    func cellHeight(for index: Int) -> CGFloat { 80.0 }

    func registerCells(_ tableView: UITableView) {
        tableView.registerCellNib(cell: SliderTableViewCell.self)
    }
}
