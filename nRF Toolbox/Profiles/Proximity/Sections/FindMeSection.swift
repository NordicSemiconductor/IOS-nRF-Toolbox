//
// Created by Nick Kibysh on 30/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class FindMeSection: Section {
    private var findMeEnabled: Bool = false
    private let action: (Bool) -> ()

    private var rssi: Int?
    private var tx: Int?

    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: FindMeTableViewCell.self)
        let title = findMeEnabled ? "SILENT ME" : "FIND ME"
        cell.update(with: rssi, tx: tx, title: title)
        cell.action = {
            self.toggle()
        }
        return cell
    }
    
    func reset() { }
    
    var numberOfItems: Int = 1
    
    var sectionTitle: String = "Signal Strength"
    
    var id: Identifier<Section>
    
    var isHidden: Bool = false
    
    init(id: Identifier<Section>, action: @escaping (Bool) -> ()) {
        self.id = id
        self.action = action
    }

    private func toggle() {
        findMeEnabled.toggle()
        action(findMeEnabled)
    }

    func update(rssi: Int?, tx: Int?) {
        self.rssi = rssi
        self.tx = tx
    }

    func cellHeight(for index: Int) -> CGFloat {
        300.0
    }
}
