//
//  UARTMacrosTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 14/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosTableViewController: UITableViewController, AlertPresenter {
    
    struct Section {
        static let name = 0
        static let preset = 1
        static let commands = 2
        static let play = 3
    }
    
    private var presetCollectionView: UARTPresetCollectionView?
    private var macros: UARTMacro
    
    init(preset: UARTPreset) {
        self.macros = .empty
        self.macros.preset = preset
        super.init(style: .grouped)
    }
    
    init(macros: UARTMacro = .empty) {
        self.macros = macros
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Macros"
        tableView.registerCellNib(cell: UARTPresetTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        tableView.registerCellNib(cell: TimeIntervalTableViewCell.self)
        tableView.registerCellClass(cell: NordicTextTableViewCell.self)
        tableView.registerCellNib(cell: NordicTextFieldCell.self)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }
    
    @objc private func save() {
        guard !macros.name.isEmpty else {
            displayErrorAlert(error: QuickError(message: "Enter marco's name"))
            return
        }
        
//        saveMacros(macros.name)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.name: return 1
        case Section.preset: return 1
        case Section.commands: return macros.commands.count + 1
        case Section.play: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.name: return tableView.dequeueCell(ofType: NordicTextFieldCell.self)
        case Section.preset: return presetCell(tableView)
        case Section.commands: return commandCell(tableView, index: indexPath.row)
        case Section.play:
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Play"
            return cell
        default:
            Log(category: .app, type: .fault).fault("Unknown section in the tableView")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.commands:
            tableView.deselectRow(at: indexPath, animated: true)
            handleCommandSectionTap(indexPath.row)
        default:
            break
        }
    }
    
    private func handleCommandSectionTap(_ index: Int) {
        guard index == macros.commands.count else { return }
        macros.commands.append(UARTMacroTimeInterval(miliseconds: 100))
        tableView.insertRows(at: [IndexPath(item: macros.commands.count - 1, section: Section.commands)], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == Section.name else { return nil }
        return "Preset Name"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == Section.commands || section == Section.name else { return 0 }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == Section.commands else { return nil }
        let v = UARTMacrosHeaderView.instance()
        v.editAction = { [unowned self] in
            self.tableView.isEditing = !self.tableView.isEditing
        }
        return v

    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == Section.commands && indexPath.row < macros.commands.count
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.section == Section.commands, indexPath.row < macros.commands.count else { return .none}
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, ip) in
            self.macros.commands.remove(at: ip.row)
            tableView.deleteRows(at: [ip], with: .automatic)
        }
        
        return [delete]
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        indexPath.section == Section.commands
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.commands && indexPath.row < macros.commands.count
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = macros.commands[sourceIndexPath.row]
        macros.commands.remove(at: sourceIndexPath.row)
        macros.commands.insert(item, at: destinationIndexPath.row)
        print(destinationIndexPath)
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard proposedDestinationIndexPath.section != Section.commands || proposedDestinationIndexPath.row >= macros.commands.count else { return proposedDestinationIndexPath }
        return IndexPath(row: macros.commands.count - 1, section: Section.commands)
    }
}

extension UARTMacrosTableViewController: UARTPresetCollectionViewDelegate {
    func selectedCommand(_ command: UARTCommandModel, at index: Int) {
        guard !(command is EmptyModel) else {
            openPresetEditor(with: command, index: index)
            return
        }
        macros.commands.append(command)
        tableView.insertRows(at: [IndexPath(item: macros.commands.count - 1, section: Section.commands)], with: .automatic)
    }
    
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int) {
        openPresetEditor(with: command, index: index)
    }
}

extension UARTMacrosTableViewController: UARTNewCommandDelegate {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int) {
        macros.preset.updateCommand(command, at: index)
        presetCollectionView?.preset = macros.preset
        viewController.dismsiss()
    }
}

// MARK: - Cells
extension UARTMacrosTableViewController {
    private func nameCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicTextFieldCell.self)
        cell.textChanged = { [unowned self] text in
            let name = text ?? ""
            self.macros.name = name
        }
        return cell
    }
    
    private func presetCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTPresetTableViewCell.self)
        cell.apply(preset: macros.preset, delegate: self)
        presetCollectionView = cell.presetCollectionView
        return cell
    }
    
    private func commandCell(_ tableView: UITableView, index: Int) -> UITableViewCell {
        guard index < macros.commands.count else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Add delay"
            return cell
        }
        
        let element = macros.commands[index]
        switch element {
        case let timeInterval as UARTMacroTimeInterval:
            let cell = tableView.dequeueCell(ofType: TimeIntervalTableViewCell.self)
            cell.apply(timeInterval: timeInterval, index: index)
            cell.callback = { [unowned self] ti, index in
                self.macros.commands[index] = ti
            }
            cell.selectionStyle = .none
            return cell
        case let command as UARTCommandModel:
            let cell = tableView.dequeueCell(ofType: NordicTextTableViewCell.self)
            cell.apply(command)
            cell.selectionStyle = .none
            return cell
        default:
            Log(category: .app, type: .fault).fault("Unknown command type")
        }
    }
}

extension UARTMacrosTableViewController {
    private func saveMacros(_ macro: UARTMacro) throws {
        let fileManager = FileManager.default
        let data = try JSONEncoder().encode(macro)
        let fileUrl = try self.fileUrl(for: macro)
            
            guard !fileManager.fileExists(atPath: fileUrl.absoluteString) else {
                throw QuickError(message: "Macro with that name already exists")
            }
            
            try data.write(to: fileUrl)
            self.navigationController?.popViewController(animated: true)
            
//            if case .none = self.fileUrl {
//                changePresenter?.newMacro(at: fileUrl)
//            } else {
//                changePresenter?.cangedMacro(at: fileUrl)
//            }
    }
    
    private func fileUrl(for macro: UARTMacro) throws -> URL {
        let fileManager = FileManager.default
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
        return documentDirectory.appendingPathComponent(macro.name).appendingPathExtension("json")
    }
}
