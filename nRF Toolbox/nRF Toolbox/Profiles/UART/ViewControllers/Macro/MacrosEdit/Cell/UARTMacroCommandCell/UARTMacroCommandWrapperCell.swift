//
//  UARTMacroCommandCell1.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import UART
import Core

class UARTMacroCommandWrapperCell: UITableViewCell {

    private struct Constants {
        static let titleHeight: CGFloat = 67
        static let utilCellHeight: CGFloat = 44
    }
    
    var model: MacrosCommandContainer!
    var expanded: Bool = false
    
    @IBOutlet private var tvHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var tableView: UITableView!
    
    //MARK: Callbacks
    var expandAction: ((UIButton) -> ())?
    var setupAndShowStepper: ((UARTIncrementViewController, UIView) -> ())?
    var timeIntervalCanged: ((Int) -> ())?
    var repeatCountCanged: ((Int) -> ())?
    var removeCommand: (() -> ())?
    
    func apply(_ model: MacrosCommandContainer, expanded: Bool = false) {
        self.model = model
        self.expanded = expanded

        tvHeightConstraint.constant = expanded
                ? Constants.utilCellHeight * 2 + Constants.titleHeight
                : Constants.titleHeight
        
        tableView.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
        tableView.backgroundColor = nil
        
    }
}

extension UARTMacroCommandWrapperCell {
    @IBAction private func remove() {
        removeCommand?()
    }
}

extension UARTMacroCommandWrapperCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expanded ? 3 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(model.command)

            cell.expandAction = self.expandAction
            cell.backgroundColor = nil
            
            cell.deleteBtn.addTarget(self, action: #selector(remove), for: .touchUpInside)

            return cell
        case 1:
            return self.tableView(tableView, repeatCellForRowAt: indexPath, repeatConut: model.repeatCount)
        case 2:
            return self.tableView(tableView, tiCellForRowAt: indexPath, delay: model.delay)
        default:
            fatalError()
        }
    }

    private func tableView(_ tableView: UITableView, repeatCellForRowAt indexPath: IndexPath, repeatConut: Int) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Repeat"
        cell.argument.text = "\(repeatConut) times"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper?(controller, label)
            controller.stepperSetup = (1, 100, repeatConut, 1)
        }

        cell.argument.stepperValueChanged = { [weak self, weak cell] val in
            self?.repeatCountCanged?(val)
            cell?.argument.text = "\(val) times"
        }

        cell.backgroundColor = nil
        
        return cell
    }

    private func tableView(_ tableView: UITableView, tiCellForRowAt indexPath: IndexPath, delay: Int) -> UITableViewCell {
                
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Time Interval"
        cell.argument.text = "\(delay) milliseconds"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper?(controller, label)
            controller.stepperSetup = (100, 10_000, delay, 100)
        }

        cell.backgroundColor = nil
        
        cell.argument.stepperValueChanged = { [weak cell] val in
            self.timeIntervalCanged?(val)
            cell?.argument.text = "\(val) milliseconds"
        }

        return cell
    }
    
}
