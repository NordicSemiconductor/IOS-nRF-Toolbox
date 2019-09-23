//
//  OptionSelectioSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 13/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct OptionSelectioSection<T>: Section {
    struct Item {
        let option: String
        var selectedCase: Identifier<T>
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    let id: Identifier<Section>
    
    let sectionTitle: String
    var items: [Item] = []
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DisclosureTableViewCell")!
        cell.textLabel?.text = items[index].option
        cell.detailTextLabel?.text = items[index].selectedCase.string
        return cell
    }
    
    
    
    
}
