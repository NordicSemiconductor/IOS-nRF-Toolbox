//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

private protocol SectionDescriptor {
    
}

private struct CommandWrapper: SectionDescriptor {
    let element: UARTMacroCommandWrapper
    var expanded: Bool
    var repeatEnabled: Bool = false
    var timeIntervalEnabled: Bool = false
}

class UARTMacrosEditViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
    }
    
    private var elements: [SectionDescriptor] = [
        CommandWrapper(element: UARTMacroCommandWrapper(), expanded: true),
        CommandWrapper(element: UARTMacroCommandWrapper(), expanded: false),
        CommandWrapper(element: UARTMacroCommandWrapper(), expanded: true)
    ]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        elements.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let element = elements[section] as? CommandWrapper else {
            return 1
        }
        return element.expanded ? 3 : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch elements[indexPath.section] {
        case let e as CommandWrapper:
            return self.tableView(tableView, commandCellForRowAt: indexPath, command: e)
        default:
            fatalError()
        }
        
        
    }
    
    private func tableView(_ tableView: UITableView, commandCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(command.element.command)
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = indexPath.row == 1 ? "Repeat" : "TimeInterval"
        cell.argument.text = indexPath.row == 1
            ? "1 time"
            : "100 miliseconds"
        
        cell.argument.labelDidPressed = { label in
            let vc = UARTIncrementViewController()
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: 110, height: 48)
            vc.popoverPresentationController?.delegate = self
            vc.popoverPresentationController?.sourceView = label
            vc.popoverPresentationController?.permittedArrowDirections = .up
            
            self.present(vc, animated: true, completion:nil)
        }
        
        return cell
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // return UIModalPresentationStyle.FullScreen
        return UIModalPresentationStyle.none
    }
}
