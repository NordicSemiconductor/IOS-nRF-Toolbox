//
//  BGMActionSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 01.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension Identifier where Value == Section {
    static let bgMActionSection: Identifier<Section> = "BGMActionSection"
}

class BGMActionSection: Section {
    
    let numberOfItems: Int = 4
    let sectionTitle: String = "Actions"
    let id: Identifier<Section> = .bgMActionSection
    let isHidden: Bool = false
    
    func cellHeight(for index: Int) -> CGFloat {
        index == 0 ? 64 : 44
    }
    
    func registerRequiredCells(for tableView: UITableView) {
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        tableView.registerCellNib(cell: BGMDisplayItemTableViewCell.self)
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        if index == 0 {
            return dequeueDisplayCell(tableView)
        }
        
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        
        switch index {
        case 1:
            cell.style = .default
            cell.textLabel?.text = "Refresh"
        case 2:
            cell.style = .default
            cell.textLabel?.text = "Clear"
        case 3:
            cell.style = .destructive
            cell.textLabel?.text = "Delete All"
        default:
            break
        }
        
        return cell
    }
    
    func didSelectRaw(at index: Int) {
        switch index {
        case 1: refreshAction(displayItemActionId)
        case 2: clearAction()
        case 3: deleteAllAction()
        default: break
        }
    }
    
    func reset() { }
    
    private var displayItemActionId: Identifier<GlucoseMonitorViewController> = .all
    var refreshAction: ((Identifier<GlucoseMonitorViewController>) -> ())!
    var clearAction: (() -> ())!
    var deleteAllAction: (() -> ())!
    
    private func dequeueDisplayCell(_ tableView: UITableView) -> BGMDisplayItemTableViewCell {
        let cell = tableView.dequeueCell(ofType: BGMDisplayItemTableViewCell.self)
        cell.callback = { index in
            let id: Identifier<GlucoseMonitorViewController> = {
                switch index {
                case 0: return .all
                case 1: return .first
                case 2: return .last
                default: return ""
                }
            }()
            
            self.displayItemActionId = id
            self.refreshAction(id)
        }
        return cell
    }
    
}
