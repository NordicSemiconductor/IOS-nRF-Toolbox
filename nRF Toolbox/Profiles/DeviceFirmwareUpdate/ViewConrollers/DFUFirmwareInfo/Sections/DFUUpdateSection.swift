//
//  DFUUpdateSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUUpdateSection: DFUActionSection {
    var action: () -> ()
    
    init(action: @escaping () -> ()) {
        self.action = action
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        cell.textLabel?.text = "Update"
        return cell
    }
    
    func reset() { }
    
    let numberOfItems: Int = 1
    
    let sectionTitle: String = ""
    
    let id: Identifier<Section> = "DFUUpdateSection"
    
    let isHidden: Bool = false
    
}
