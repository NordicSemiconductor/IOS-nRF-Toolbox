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

extension UARTMacroTimeInterval: SectionDescriptor {
    
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
        self.elements = macros.elements.compactMap {
            switch $0 {
            case let c as UARTMacroCommandWrapper:
                return CommandWrapper(element: c, expanded: c.repeatCount > 1)
            case let ti as UARTMacroTimeInterval:
                return ti
            default:
                return nil
            }
        }

        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismsiss))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItem = saveItem
        navigationItem.title = "Edit macros"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroWaitCell.self)
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
        case let ti as UARTMacroTimeInterval:
            return self.tableView(tableView, timeIntervalCellForRowAt: indexPath, timeInterval: ti)
        default:
            fatalError()
        }
        
    }
    
    @IBAction private func save() {
        
    }
    
}

//MARK: - Table View
extension UARTMacrosEditViewController {
    private func tableView(_ tableView: UITableView, timeIntervalCellForRowAt indexPath: IndexPath, timeInterval: UARTMacroTimeInterval) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroWaitCell.self)
        
        let milliseconds = Int(timeInterval.timeInterval * 1000)
        cell.intervalLabel.text = "\(milliseconds) milliseconds"
        cell.presentController = { [weak self] label, controller in
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (100, 10_000, milliseconds, 100)
        }
        
        cell.timeIntervalChanged = { [weak cell, unowned self] ti in
            
            (self.elements[indexPath.section] as! UARTMacroTimeInterval).timeInterval = Double(ti) / 1000.0
            cell?.intervalLabel.text = "\(ti) milliseconds"
        }
        
        return cell
    }
    
    private func tableView(_ tableView: UITableView, commandCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {

        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(command.element.command)
            
            cell.expandAction = { [weak self] sender in
                guard var command = self?.elements[indexPath.section] as? CommandWrapper else {
                    return
                }
                
                command.expanded.toggle()
                sender.isHighlighted = command.expanded
                
                self?.elements[indexPath.section] = command
                tableView.reloadSections([indexPath.section], with: .automatic)
            }
            
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
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (1, 100, command.element.repeatCount, 1)
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
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (100, 10_000, command.element.timeInterval, 100)
        }

        cell.argument.stepperValueChanged = { [weak cell] val in
            cell?.argument.text = "\(val) milliseconds"
            (self.elements[indexPath.section] as! CommandWrapper).element.timeInterval = val
        }
        
        return cell
    }
    
    private func setupAndShowStepper(_ controller: UARTIncrementViewController, on view: UIView) {
        controller.modalPresentationStyle = .popover
        controller.preferredContentSize = CGSize(width: 110, height: 48)
        
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.permittedArrowDirections = .up
        controller.popoverPresentationController?.delegate = self
        
        self.present(controller, animated: true)
    }
}

extension UARTMacrosEditViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
