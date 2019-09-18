//
//  DetailsTableViewSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct DetailsTableViewSection: Section {
    var id: Identifier<Section> 
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let detailsCell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
        detailsCell.update(with: items[index])
        return detailsCell
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    var sectionTitle: String
    var items: [DetailsTableViewCellModel]
}
