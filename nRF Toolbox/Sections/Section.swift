//
//  Section.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct Identifier: Hashable {
    let string: String
}

extension Identifier: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        string = value
    }
}

extension Identifier: CustomStringConvertible {
    var description: String {
        return string
    }
}

extension Identifier {
    struct TableSection {
        static let battery: Identifier = "Battery"
        static let disconnect: Identifier = "Disconnect"
        static let bgmReadings: Identifier = "BGMReadings"
        static let singleActionSection: Identifier = "SingleActionSection"
    }
}

protocol Section {
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell
    var numberOfItems: Int { get }
    var sectionTitle: String { get }
    var id: Identifier { get }
}
