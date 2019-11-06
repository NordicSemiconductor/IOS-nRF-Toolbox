//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import Charts

class ContinuousGlucoseChartData: ChartDataSection<ContinuousGlucoseMonitorMeasurement> {
    override var numberOfItems: Int { 2 }

    override func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        if index == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
            cell?.textLabel?.text = "All Values"
            cell?.accessoryType = .disclosureIndicator
            return cell!
        } else {
            return super.dequeCell(for: index, from: tableView)
        }
    }

    override func update(with data: ContinuousGlucoseMonitorMeasurement) {
        super.update(with: data)
    }

    override func transform(_ item: ContinuousGlucoseMonitorMeasurement) -> (x: Double, y: Double) {
        (item.date!.timeIntervalSince1970, Double(item.glucoseConcentration))
    }

    override func cellHeight(for index: Int) -> CGFloat {
        index == 0 ? .defaultTableCellHeight : super.cellHeight(for: index)
    }
}
