//
//  Section.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol Section {
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell
    var numberOfItems: Int { get }
    var sectionTitle: String { get }
    var id: Identifier<Section> { get }
}

extension Identifier where Value == Section {
    static let battery: Identifier<Section> = "battery"
    static let disconnect: Identifier<Section> = "Disconnect"
    static let bgmReadings: Identifier<Section> = "BGMReadings"
    static let selectionResult: Identifier<Section> = "SelectionResultSection"
    static let optionSelection: Identifier<Section> = "OptionSelection"
    static let details: Identifier<Section> = "DetailsSection"
    static let cycling: Identifier<Section> = "Cycling"
}
