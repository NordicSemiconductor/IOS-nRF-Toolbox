//
//  UARTEditMacrosVC.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import IntentsUI

protocol UARTEditMacrosDelegate: class {
    func saveMacrosUpdate(name: String, color: UARTColor)
}

class UARTEditMacrosVC: UITableViewController, AlertPresenter {
    
    private var name: String?
    private var color: UARTColor?
    
    weak var editMacrosDelegate: UARTEditMacrosDelegate!
    
    init(name: String?, color: UARTColor?) {
        self.name = name
        self.color = color
        
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
        
        tableView.registerCellNib(cell: UARTColorSelectorCell.self)
        tableView.registerCellNib(cell: NordicTextFieldCell.self)
        if #available(iOS 12.0, *) {
            tableView.registerCellClass(cell: AddSiriShortcutTableViewCell.self)
        }
        setupNavigationAppearance()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 60
        case 1: return 190
        default: return 50
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueCell(ofType: NordicTextFieldCell.self)
            cell.textField.text = name
            cell.textField.font = UIFont.gtEestiDisplay(.regular, size: 17)
            
            cell.textChanged = { [weak self] name in
                self?.name = name
            }
            
            return cell 
        case 1:
            let cell = tableView.dequeueCell(ofType: UARTColorSelectorCell.self)
            cell.color = color
            
            cell.colorUpdated = { [weak self] color in
                self?.color = color
            }
            
            return cell
            
        case 2:
            if #available(iOS 12.0, *) {
                let cell = tableView.dequeueCell(ofType: AddSiriShortcutTableViewCell.self)
                cell.shortcutDelegate = self 
                return cell
                
            } else {
                fatalError()
            }
            
            
        default:
            SystemLog.fault("Section data not found", category: .ui)
        }
        
    }

}

extension UARTEditMacrosVC {
    @IBAction private func save() {
        guard let name = self.name, let color = self.color, !name.isEmpty else {
            displayErrorAlert(error: QuickError(message: "Name should not be empty and color should be selected"))
            return
        }
        
        editMacrosDelegate.saveMacrosUpdate(name: name, color: color)
    }
    
    @IBAction private func cancel() {
        navigationController?.popViewController(animated: true)
    }
}

extension UARTEditMacrosVC {
    private func setupNavigationAppearance() {
        navigationItem.title = "Edit Macros"
        
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveItem
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelItem
    }
}

@available(iOS 12.0, *)
extension UARTEditMacrosVC: INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension UARTEditMacrosVC: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        
    }
    
    
}
