//
//  UARTMacroViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol ChangePresenter: class {
    func cangedMacro(at url: URL)
    func newMacro(at url: URL)
}

class UARTMacroViewController: UIViewController, AlertPresenter {
    private let btManager: BluetoothManager

    @IBOutlet private var rootStackView: UIStackView!
    @IBOutlet var commandListCollectionView: UARTPresetCollectionView!
    @IBOutlet var commandOrderTableView: UITableView!
    @IBOutlet var timeStepper: UIStepper!
    @IBOutlet var playBtn: NordicButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    
    private var preset: UARTPreset
    private var macros: [UARTMacroElement] = []
    private var fileUrl: URL?
    
    private lazy var dispatchSource = DispatchSource.makeTimerSource(queue: .main)
    
    weak var changePresenter: ChangePresenter?
    
    init(bluetoothManager: BluetoothManager, preset: UARTPreset, macroUrl: URL? = nil) {
        self.btManager = bluetoothManager
        self.preset = preset
        self.fileUrl = macroUrl
        super.init(nibName: "UARTMacroViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commandOrderTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        commandListCollectionView.preset = preset
        commandListCollectionView.presetDelegate = self
        
        commandOrderTableView.isEditing = true
        
        playBtn.style = .mainAction
        navigationItem.title = "Create new Macro"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        commandOrderTableView.registerCellClass(cell: NordicActionTableViewCell.self)
        commandOrderTableView.registerCellNib(cell: TimeIntervalTableViewCell.self)
        commandOrderTableView.registerCellClass(cell: NordicTextTableViewCell.self)
        
        self.fileUrl.flatMap(preloadMacro(_:))
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
    }
    
    @IBAction func play() {
        let macro = UARTMacro(name: nameTextField.text ?? "", delay: Int(timeStepper.value), commands: macros)
        btManager.send(macro: macro)
    }
    
    @objc private func save() {
        guard let name = nameTextField.text, !name.isEmpty else {
            displayErrorAlert(error: QuickError(message: "Enter marco's name"))
            return
        }
        
        fileUrl.flatMap {
            do {
                try FileManager.default.removeItem(at: $0)
            } catch let error {
                displayErrorAlert(error: error)
            }
        }
        
        saveMacros(name)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        rootStackView.axis = view.frame.width < 550 ? .vertical : .horizontal
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        commandListCollectionView.collectionViewLayout.invalidateLayout()
    }
}

extension UARTMacroViewController {
    private func preloadMacro(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let macro = try JSONDecoder().decode(UARTMacro.self, from: data)
            nameTextField.text = macro.name
            macros = macro.commands
            timeStepper.value = Double(macro.delay)
            timeLabel.text = "\(macro.delay) ms"
            navigationItem.title = "Edit Macros"
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
    
    private func saveMacros(_ name: String) {
        let fileManager = FileManager.default
        do {
            let macro = UARTMacro(name: name, delay: Int(timeStepper.value), commands: macros)
            let data = try JSONEncoder().encode(macro)
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
            try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
            let fileUrl = documentDirectory
                .appendingPathComponent(name)
                .appendingPathExtension("json")
            
            guard !fileManager.fileExists(atPath: fileUrl.absoluteString) else {
                throw QuickError(message: "Macro with that name already exists")
            }
            
            try data.write(to: fileUrl)
            self.navigationController?.popViewController(animated: true)
            
            if case .none = self.fileUrl {
                changePresenter?.newMacro(at: fileUrl)
            } else {
                changePresenter?.cangedMacro(at: fileUrl)
            }
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

extension UARTMacroViewController: UARTPresetCollectionViewDelegate {
    func selectedCommand(_ command: UARTCommandModel, at index: Int) {
        guard !(command is EmptyModel) else { return }
        macros.append(command)
        commandOrderTableView.insertRows(at: [IndexPath(row: macros.count - 1, section: 0)], with: .automatic)
    }
    
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int) {
        let vc = UARTNewCommandViewController(command: command, index: index)
        vc.delegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
        self.present(nc, animated: true)
        commandListCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .top)
    }
}

extension UARTMacroViewController: UARTNewCommandDelegate {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int) {
        guard let selectedItemIndex = commandListCollectionView.indexPathsForSelectedItems?.first?.item else {
            return
        }
        
        preset.updateCommand(command, at: selectedItemIndex)
        commandListCollectionView.preset = preset
        viewController.dismsiss()
    }
    
}

extension UARTMacroViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? macros.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section != 0 {
            return addTimeInterval(tableView)
        }
        
        switch macros[indexPath.row] {
        case is UARTCommandModel:
            return commandCell(tableView, index: indexPath.row)
        case is UARTMacroTimeInterval:
            return timeIntervalCell(tableView, index: indexPath.row)
        default:
            return UITableViewCell()
        }
    }
    
    private func commandCell(_ tableView: UITableView, index: Int) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicTextTableViewCell.self)
        let command = self.macros[index] as! UARTCommandModel
        cell.apply(command)
        cell.selectionStyle = .none
        return cell
    }
    
    private func timeIntervalCell(_ tableView: UITableView, index: Int) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: TimeIntervalTableViewCell.self)
        let timeInterval = self.macros[index] as! UARTMacroTimeInterval
        cell.apply(timeInterval: timeInterval, index: index)
        cell.callback = { [unowned self] ti, index in
            self.macros[index] = ti
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func addTimeInterval(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        cell.textLabel?.text = "Add pause"
        return cell
    }
    
}

extension UARTMacroViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            macros.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, ip) in
            self.macros.remove(at: ip.row)
            tableView.deleteRows(at: [ip], with: .automatic)
        }
        
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard proposedDestinationIndexPath.section == 1 else { return proposedDestinationIndexPath }
        return IndexPath(row: macros.count - 1, section: 0)
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == 0 ? .delete : .none
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = macros[sourceIndexPath.row]
        macros.remove(at: sourceIndexPath.row)
        macros.insert(item, at: destinationIndexPath.row)
        print(destinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        macros.append(UARTMacroTimeInterval(miliseconds: 100))
        tableView.insertRows(at: [IndexPath(row: macros.count - 1, section: 0)], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        indexPath.section == 1
    }
}

extension UARTMacroViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
