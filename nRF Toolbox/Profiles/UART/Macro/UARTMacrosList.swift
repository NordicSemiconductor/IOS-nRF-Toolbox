//
//  UARTMacrosList.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosList: UITableViewController, CloseButtonPresenter, AlertPresenter {

    private var macrosNames: [String] = []
    
    private let btManager: BluetoothManager
    private let macrosFileManager = UARTMacroFileManager()
    private let preset: UARTPreset
    
    init(bluetoothManager: BluetoothManager, preset: UARTPreset) {
        self.btManager = bluetoothManager
        self.preset = preset
        super.init(style: .grouped)
        tabBarItem = UITabBarItem(title: "Macros", image: TabBarIcon.uartMacros.image, selectedImage: TabBarIcon.uartMacros.filledImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        macrosNames = loadMacrosList()
        
        tableView.registerCellClass(cell: NordicTextTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        setupCloseButton()
        
        navigationItem.title = "Saved Macros"
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? macrosNames.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Add New..."
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: NordicTextTableViewCell.self)
        cell.textLabel?.text = macrosNames[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: UARTMacrosTableViewController
        if indexPath.section == 0 {
            do {
                let macros = try displayOnError(macrosFileManager.macros(for: macrosNames[indexPath.row]))
                vc = UARTMacrosTableViewController(macros: macros, bluetoothManager: btManager)
            } catch {
                return
            }
        } else {
            vc = UARTMacrosTableViewController(preset: UARTPreset.empty, bluetoothManager: btManager)
        }
        
        vc.macrosDelegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Saved macros" : "Create new one"
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        indexPath.section == 0 ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let macroName = macrosNames[indexPath.row]
        try? displayOnError(macrosFileManager.removeMacro(name: macroName))
        macrosNames = loadMacrosList()
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

extension UARTMacrosList {
    private func loadMacrosList() -> [String] {
        (try? displayOnError( macrosFileManager.macrosList()) ) ?? []
    }
}

extension UARTMacrosList: UARTMacroViewControllerDelegate {
    func macrosController(_ controller: UARTMacrosTableViewController, created macros: UARTMacro) {
        reloadData()
        controller.navigationController?.popViewController(animated: true)
    }
    
    func macrosController(_ controller: UARTMacrosTableViewController, changed macros: UARTMacro) {
        reloadData()
        controller.navigationController?.popViewController(animated: true)
    }
    
    private func reloadData() {
        macrosNames = loadMacrosList()
        tableView.reloadData()
    }
    
}
