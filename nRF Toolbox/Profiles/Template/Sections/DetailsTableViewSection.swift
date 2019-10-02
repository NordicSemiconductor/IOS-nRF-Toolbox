//
//  DetailsTableViewSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DetailsTableViewSection<C>: Section {
    lazy var isHidden: Bool = items.count == 0
    
    typealias SectionUpdated = (Identifier<Section>) -> ()
    typealias ItemUpdated = (Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ()

    let id: Identifier<Section>
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let detailsCell = tableView.dequeueCell(ofType: DetailsTableViewCell.self)
        detailsCell.update(with: items[index])
        return detailsCell
    }
    
    func reset() {
        items = [] 
    }
    
    var numberOfItems: Int { items.count }
    
    var sectionTitle: String { "" }
    var items: [DetailsTableViewCellModel] = []
    var itemUpdated: ItemUpdated?
    var sectionUpdated: SectionUpdated?
    
    init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        self.id = id
        self.sectionUpdated = sectionUpdated
        self.itemUpdated = itemUpdated
    }
    
    func update(with characteristic: C) {
        sectionUpdated?(id)
    }
    
}
