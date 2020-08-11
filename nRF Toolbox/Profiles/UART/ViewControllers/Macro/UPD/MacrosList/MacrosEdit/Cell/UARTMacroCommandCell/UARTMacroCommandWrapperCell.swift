//
//  UARTMacroCommandCell1.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacroCommandWrapperCell: UITableViewCell {

    private struct Constants {
        static let titleHeight: CGFloat = 67
        static let utilCellHeight: CGFloat = 44
    }
    
    var model: CommandWrapper!
    
    @IBOutlet private var tvHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var tableView: UITableView!
    
    //MARK: Callbacks
    var expandAction: ((UIButton) -> ())?
    var setupAndShowStepper: ((UARTIncrementViewController, UIView) -> ())?
    var timeIntervalCanged: ((Int) -> ())?
    var repeatCountCanged: ((Int) -> ())?
    
    func apply(_ model: CommandWrapper) {
        self.model = model

        tvHeightConstraint.constant = model.expanded
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension UARTMacroCommandWrapperCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard model != nil else { return 0 }
        return model.expanded ? 3 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let command = model.element.command
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(command)

            cell.expandAction = self.expandAction
            cell.backgroundColor = nil

            return cell
        case 1:
            return self.tableView(tableView, repeatCellForRowAt: indexPath, command: model)
        case 2:
            return self.tableView(tableView, tiCellForRowAt: indexPath, command: model)
        default:
            fatalError()
        }
    }

    private func tableView(_ tableView: UITableView, repeatCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Repeat"
        cell.argument.text = "\(command.element.repeatCount) times"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper?(controller, label)
            controller.stepperSetup = (1, 100, command.element.repeatCount, 1)
        }

        cell.argument.stepperValueChanged = { [weak self, weak cell] val in
            self?.repeatCountCanged?(val)
            cell?.argument.text = "\(val) times"
        }

        cell.backgroundColor = nil
//        cell.contentView.backgroundColor = nil
        
        return cell
    }

    private func tableView(_ tableView: UITableView, tiCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Time Interval"
        cell.argument.text = "\(command.element.timeInterval) milliseconds"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper?(controller, label)
            controller.stepperSetup = (100, 10_000, command.element.timeInterval, 100)
        }

        cell.backgroundColor = nil
//        cell.contentView.backgroundColor = nil
        
        cell.argument.stepperValueChanged = { [weak cell] val in
            self.timeIntervalCanged?(val)
            cell?.argument.text = "\(val) milliseconds"
        }

        return cell
    }
    
}
