//
//  AccessoriesSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 30.03.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import HomeKit

struct AccessoriesSection: Section {
    var items: [HMAccessory] = []
    var home: HMHome?
    
    init(sectionTitle: String, footer: String?, id: Identifier<Section>) {
        self.sectionTitle = sectionTitle
        self.id = id
        self.sectionFooter = footer
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let accessory = items[index]
        
        let homeName = home?.name
        let roomName = accessory.room?.name
        let detailsTitle = [roomName, homeName].compactMap { $0 }.joined(separator: " in ")
        
        let cell = tableView.dequeueCell(ofType: NordicBottomDetailsTableViewCell.self)
        cell.textLabel?.text = accessory.name
        cell.detailTextLabel?.text = detailsTitle
        
        return cell
    }
    
    mutating func reset() { }
    
    var numberOfItems: Int { items.count }
    
    var sectionTitle: String
    var sectionFooter: String?
    
    var id: Identifier<Section>
    
    var isHidden: Bool { items.isEmpty }
    
}
