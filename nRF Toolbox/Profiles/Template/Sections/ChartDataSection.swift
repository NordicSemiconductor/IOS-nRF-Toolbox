//
// Created by Nick Kibysh on 28/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ChartDataSection<T>: Section {
    var items: [T] = []

    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let chartValues = items.map(transform)
        let cell = tableView.dequeueCell(ofType: LinearChartTableViewCell.self)
        cell.update(with: chartValues)
        return cell
    }

    func reset() {
        items.removeAll()
    }

    var sectionTitle: String { "" }
    var numberOfItems: Int { 1 }

    var id: Identifier<Section>
    var isHidden: Bool = false

    func update(with data: T) {
        self.items.append(data)
    }

    func transform(_ item: T) -> (x: Double, y: Double) { (0, 0) }

    init(id: Identifier<Section>) {
        self.id = id
    }
}
