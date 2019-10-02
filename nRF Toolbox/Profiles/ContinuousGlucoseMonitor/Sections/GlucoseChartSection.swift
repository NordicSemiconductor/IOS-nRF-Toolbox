//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import Charts

class ChartData<T>: NSObject, Section {
    var items: [T] = []

    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        if index == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
            cell?.textLabel?.text = "All Values"
            cell?.accessoryType = .disclosureIndicator
            return cell!
        }
        let chartValues = items.map(transform)
        let cell = tableView.dequeueCell(ofType: LinearChartTableViewCell.self)
        cell.update(with: chartValues)
        return cell
    }

    func reset() {
        items.removeAll()
    }

    var sectionTitle: String { "" }
    var numberOfItems: Int { 2 }

    var id: Identifier<Section>
    var isHidden: Bool = false

    func handleNewValue(_ value: T) {
        self.items.append(value)
    }

    func update(with data: T) {
        handleNewValue(data)
    }

    func transform(_ item: T) -> (x: Double, y: Double) { (0, 0) }

    init(id: Identifier<Section>) {
        self.id = id
    }
}

class LinearChartSection: ChartData<ContinuousGlucoseMonitorMeasurement> {
    override func update(with data: ContinuousGlucoseMonitorMeasurement) {
        super.update(with: data)
    }

    override func transform(_ item: ContinuousGlucoseMonitorMeasurement) -> (x: Double, y: Double) {
        (item.date!.timeIntervalSince1970, Double(item.glucoseConcentration))
    }
}

struct RandomValueSequence: IteratorProtocol {
    let top, bottom: Double
    private var value: Double
    let delta: Double

    init(top: Double, bottom: Double, value: Double, delta: Double = 1.0) {
        self.top = top
        self.bottom = bottom
        self.value = value
        self.delta = delta
    }

    mutating func next() -> Double? {
        let rand = Double.random(in: -delta...delta)

        let inRange: (Double, Double, Double) -> Double = { minEdge, maxEdge, val in
            min(maxEdge, max(minEdge, val))
        }
        value = inRange(bottom, top, value + rand)
        return value
    }
}