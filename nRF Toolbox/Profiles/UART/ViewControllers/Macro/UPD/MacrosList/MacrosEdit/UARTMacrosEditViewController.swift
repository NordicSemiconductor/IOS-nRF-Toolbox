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
    var element: UARTMacroCommandWrapper
    var expanded: Bool = true
    var repeatEnabled: Bool = true
    var timeIntervalEnabled: Bool = true
}

class UARTMacrosEditViewController: UITableViewController {

    init(macros: UARTMacro) {
        self.macros = macros
        self.elements = macros.elements.map { CommandWrapper(element: $0 as! UARTMacroCommandWrapper) }

        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
        tableView.reloadData()
    }

    let macros: UARTMacro
    private var elements: [SectionDescriptor]

    override func numberOfSections(in tableView: UITableView) -> Int {
        elements.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let command = self.elements[section] as? CommandWrapper else {
            return 1
        }
        return command.expanded ? 3 : 1
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

        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(command.element.command)
            return cell
        case 1:
            return self.tableView(tableView, repeatCellForRowAt: indexPath, command: command)
        case 2:
            return self.tableView(tableView, tiCellForRowAt: indexPath, command: command)
        default:
            fatalError()
        }
    }

    private func tableView(_ tableView: UITableView, repeatCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Repeat"
        cell.argument.text = "\(command.element.repeatCount) times"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.present(controller, animated: true)
            controller.stepperSetup = (1, 100, command.element.repeatCount)
        }

        cell.argument.stepperValueChanged = { [weak cell] val in
            cell?.argument.text = "\(val) times"
            (self.elements[indexPath.section] as! CommandWrapper).element.repeatCount = val
        }
        
        return cell
    }

    private func tableView(_ tableView: UITableView, tiCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Time Interval"
        cell.argument.text = "\(command.element.timeInterval) milliseconds"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.present(controller, animated: true)
            controller.stepperSetup = (100, 10_000, command.element.timeInterval)
        }

        cell.argument.stepperValueChanged = { [weak cell] val in
            cell?.argument.text = "\(val) times"
            (self.elements[indexPath.section] as! CommandWrapper).element.timeInterval = val
        }
        
        return cell
    }
}
