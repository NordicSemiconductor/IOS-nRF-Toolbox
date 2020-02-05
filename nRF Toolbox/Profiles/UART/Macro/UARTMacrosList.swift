//
//  UARTMacrosList.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosList: UITableViewController, CloseButtonPresenter, AlertPresenter {

    private var files: [URL] = []
    private var fileNames: [String] {
        files.map { $0.deletingPathExtension().lastPathComponent }
    }
    
    private let btManager: BluetoothManager
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
        self.files = loadMacrosList()
        
        tableView.register(NordicTextTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(NordicActionTableViewCell.self, forCellReuseIdentifier: "Action")
        setupCloseButton()
        
        navigationItem.title = "Saved Macros"
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? files.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Action")
            cell?.textLabel?.text = "Add New..."
            return cell!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = fileNames[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileUrl: URL? = indexPath.section == 0 ? files[indexPath.row] : nil
        let vc = UARTMacroViewController(bluetoothManager: btManager, preset: preset, macroUrl: fileUrl)
        vc.changePresenter = self 
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Saved macros" : "Create new one"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let fileUrl = files[indexPath.row]
        do {
            try FileManager.default.removeItem(at: fileUrl)
            files.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

extension UARTMacrosList {
    private func loadMacrosList() -> [URL] {
        let fileManager = FileManager.default
        do {
            let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("macros")
            let fileList = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            let files = fileList
            files.forEach { print($0) }
            return files
        } catch let error {
            print(error.localizedDescription)
        }
        return []
    }
}

extension UARTMacrosList: ChangePresenter {
    private func reloadData() {
        files = loadMacrosList()
        tableView.reloadData()
    }
    
    func cangedMacro(at url: URL) {
        reloadData()
    }
    
    func newMacro(at url: URL) {
        reloadData()
    }
    
    
}
