//
//  TimeSliderSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class TimeIntervalSection: Section {
    private var timeSliderModel = StepperCellModel(min: 1, max: 10, step: 1, value: 1)

    let timeIntervalChanged: (Int) -> ()

    func dequeCell(for index: Int, from tableView: UIKit.UITableView) -> UIKit.UITableViewCell {
        let cell = tableView.dequeueCell(ofType: StepperTableViewCell.self)
        cell.update(with: timeSliderModel)
        cell.timeIntervalChanges = { [unowned self] ti in
            self.timeSliderModel.value = Double(ti)
            self.timeIntervalChanged(ti)
        }
        return cell
    }

    func reset() { }

    let numberOfItems: Int = 1
    let sectionTitle: String = "Time Interval"
    let id: Identifier<Section>
    let isHidden: Bool = false

    init(id: Identifier<Section>, timeIntervalChanged: @escaping (Int) -> () ) {
        self.id = id
        self.timeIntervalChanged = timeIntervalChanged
    }
}
