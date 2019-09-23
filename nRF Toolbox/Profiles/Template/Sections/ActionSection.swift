//
//  ActionSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 11/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct ActionSectionItem {
    enum Style {
        case `default`, destructive
    }
    
    let title: String
    let style: Style
    let action: () -> ()
    
    init(title: String, style: Style = .default, action: @escaping () -> ()) {
        self.title = title
        self.style = style
        self.action = action
    }
}

struct ActionSection: Section {
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let item = items[index]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell")
        
        cell?.textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
        cell?.textLabel?.text = item.title
        cell?.textLabel?.textColor = {
            switch item.style {
            case .default: return UIColor.Button.action
            case .destructive: return UIColor.Button.destructive
            }
        }()
        return cell!
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    var sectionTitle: String
    let id: Identifier<Section>
    var items: [ActionSectionItem] = []
    
    init(id: Identifier<Section>, sectionTitle: String, items: [ActionSectionItem]) {
        self.id = id
        self.sectionTitle = sectionTitle
        self.items = items
    }
    
}
