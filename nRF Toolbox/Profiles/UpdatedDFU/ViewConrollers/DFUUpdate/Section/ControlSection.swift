//
//  ControlSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension Identifier where Value == ControlSection.Item {
    static let resume = Identifier<Value>(string: "resume")
    static let pause = Identifier<Value>(string: "pause")
    static let showLog = Identifier<Value>(string: "showLog")
    static let retry = Identifier<Value>(string: "retry")
    static let done = Identifier<Value>(string: "done")
    static let stop = Identifier<Value>(string: "stop")
}

class ControlSection: Section {
    
    struct Item {
        let id: Identifier<Item>
        let title: String
        
        static let pause = Item(id: .pause, title: "Pause")
        static let resume = Item(id: .resume, title: "Resume")
        static let showLog = Item(id: .showLog, title: "Show Log")
        static let retry = Item(id: .retry, title: "Retry")
        static let done = Item(id: .done, title: "Done")
        static let stop = Item(id: .stop, title: "Stop")
    }
    
    var callback: ((Item) -> ())!
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        let item = items[index]
        
        if item.id == .stop {
            cell.textLabel?.textColor = .nordicRed
        } else {
            cell.textLabel?.textColor = .systemBlue
        }
        
        cell.textLabel?.text = item.title
        return cell
    }
    
    func reset() { }
    func didSelectItem(at index: Int) {
        let item = items[index]
        callback(item)
    }
    
    var numberOfItems: Int {
        items.count
    }
    
    var sectionTitle: String = ""
    var id: Identifier<Section> = "ControlSection"
    var isHidden: Bool { items.isEmpty }
    var items: [Item] = []
    
    
}
