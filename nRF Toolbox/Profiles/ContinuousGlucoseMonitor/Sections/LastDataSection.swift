//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class LastGlucoseValueSection: DetailsTableViewSection<ContinuousGlucoseMonitorMeasurement> {
    override var sectionTitle: String { "Last Glucose Value" }

    override func update(with characteristic: ContinuousGlucoseMonitorMeasurement) {
        let stringValue = String(format: "%.2f mmol/L", characteristic.glucoseConcentration)
        let item = DefaultDetailsTableViewCellModel(title: "Glucose Concentration", value: stringValue)
        items = [item]
        super.update(with: characteristic)
    }
    
    override func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = super.dequeCell(for: index, from: tableView)
        cell.selectionStyle = .none
        return cell
    }
}
