//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class StartStopSection: ActionSection {
    typealias VoidAction = () -> ()

    private let startItem: ActionSectionItem
    private let stopItem: ActionSectionItem

    private var isStopped: Bool = false
    override var numberOfItems: Int { 1 }

    override func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let item = isStopped ? startItem : stopItem
        return dequeueCell(item: item, at: index, from: tableView)
    }

    init(startAction: @escaping VoidAction, stopAction: @escaping VoidAction, id: Identifier<Section>) {
        stopItem = ActionSectionItem(title: "Stop Session", style: .destructive, action: stopAction)
        startItem = ActionSectionItem(title: "Start Session", action: startAction)

        super.init(id: id, sectionTitle: "Start / Stop Session", items: [startItem, stopItem])
    }

    func toggle() {
        (isStopped ? startItem : stopItem).action()
        isStopped.toggle()
    }

}
