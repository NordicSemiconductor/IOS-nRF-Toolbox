//
// Created by Nick Kibysh on 27/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class GlucoseValueList: UITableViewController {
    let items: [ContinuousGlucoseMonitorMeasurement]

    init(items: [ContinuousGlucoseMonitorMeasurement]) {
        self.items = items
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "All Records"
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
        cell.selectionStyle = .none
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        cell.textLabel?.text = dateFormatter.string(from: item.date!)
        let stringValue = String(format: "%.2f mmol/L", item.glucoseConcentration)
        cell.detailTextLabel?.text = stringValue
        return cell
    }
}

