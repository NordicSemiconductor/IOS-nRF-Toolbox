//
// Created by Nick Kibysh on 04/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

private extension Array where Element == Double {
    func median() -> Double {
        let sorted = self.sorted()
        if sorted.count % 2 == 0 {
            return (sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1]) / 2
        } else {
            return sorted[(sorted.count - 1) / 2]
        }
    }
}

class ApproxDistanceSection: Section {
    private var tmpData: [Double] = []
    private var items: [(TimeInterval, Double)] = []

    func dequeCell(for index: Int, from tableView: UIKit.UITableView) -> UIKit.UITableViewCell {
        if index == 0 {
            let detailsCell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
            let distance = Measurement<UnitLength>(value: items.last?.1 ?? .infinity, unit: .millimeters)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
            let item = DefaultDetailsTableViewCellModel(title: "Approximate Distance", value: formatter.string(from: distance))
            detailsCell.update(with: item)
            return detailsCell
        } else {
            let chartValues = items
            let cell = tableView.dequeueCell(ofType: LinearChartTableViewCell.self)
            cell.update(with: chartValues)
            return cell
        }
    }

    func reset() {
        tmpData.removeAll()
        items.removeAll()
    }

    private(set) var numberOfItems: Int = 2
    private(set) var sectionTitle: String = "Distance"
    let id: Identifier<Section>
    var isHidden: Bool {
        false
    }

    init(id: Identifier<Section>) {
        self.id = id
    }

    func update(rssi: Int, tx: Int) {
        tmpData.append(distance(rssi: rssi, tx: tx))
        guard tmpData.count >= 10 else {
            return
        }

        let median = tmpData.median()
        tmpData.removeAll()
        items.append((Date().timeIntervalSince1970, median))
    }

    private func distance(rssi: Int, tx: Int) -> Double {
        pow(10, (Double(tx - rssi) / 20.0))
    }

    func cellHeight(for index: Int) -> CGFloat {
        index == 0 ? .defaultTableCellHeight : 350
    }
}