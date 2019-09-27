//
//  BGMSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class BGMSection: Section {
    let id: Identifier<Section> = .bgmReadings
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: BGMTableViewCell.self)
        let reading = items[index]
        cell.update(with: reading)
        return cell
    }
    
    func reset() {
        items = []
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    var sectionTitle: String = "Readings"
    
    private (set) var items: [GlucoseReading] = []
    
    func clearReadings() {
        items.removeAll()
    }
    
    func update(reading: GlucoseReading) {
        guard let index = items.firstIndex(where: { $0 == reading }) else {
            items.append(reading)
            return
        }
        items[index] = reading
    }
    
    func update(context: GlucoseReadingContext) {
        guard let index = items.firstIndex(where: { $0.sequenceNumber == context.sequenceNumber }) else {
            Log(category: .ble, type: .error).log(message: "Glucose measurement with sequence number: \(context.sequenceNumber) not found")
            return
        }
        
        items[index].context = context
    }
}
