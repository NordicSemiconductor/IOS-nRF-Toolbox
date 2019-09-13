//
//  SingleActionSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class SingleActionSection: Section {
    let id: Identifier<Section>
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell")
        cell?.textLabel?.text = buttonTitle
        cell?.textLabel?.textColor = {
            switch self.style {
            case .default: return .nordicLake
            case .destructive: return .nordicRed
            }
        }()
        return cell!
    }
    
    private let style: ActionSectionItem.Style
    
    var sectionTitle: String
    let numberOfItems: Int = 1
    let buttonTitle: String
    let action: () -> ()
    
    init(id: Identifier<Section>, sectionTitle: String? = nil, buttonTitle: String, style: ActionSectionItem.Style = .default, action: @escaping () -> ()) {
        self.sectionTitle = sectionTitle ?? ""
        self.buttonTitle = buttonTitle
        self.action = action
        self.style = style
        self.id = id 
    }
}
