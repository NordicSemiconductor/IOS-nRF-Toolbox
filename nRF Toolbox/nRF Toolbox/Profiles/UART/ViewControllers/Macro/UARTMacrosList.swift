/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

class UARTMacrosList: UITableViewController, CloseButtonPresenter, AlertPresenter {

    private var macros: [UARTMacro] = []
    
    private let btManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager) {
        self.btManager = bluetoothManager
        super.init(style: .grouped)
        tabBarItem = UITabBarItem(title: "Macros", image: TabBarIcon.uartMacros.image, selectedImage: TabBarIcon.uartMacros.filledImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        macros = loadMacrosList()
        
        tableView.registerCellClass(cell: NordicTextTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        setupCloseButton()
        
        navigationItem.title = "Saved Macros"
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? macros.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Add New..."
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: NordicTextTableViewCell.self)
        cell.textLabel?.text = macros[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: UARTMacrosTableViewController
        if indexPath.section == 0 {
            do {
                fatalError()
//                let macros = try displayOnError(macrosFileManager.macros(for: macrosNames[indexPath.row]))
//                vc = UARTMacrosTableViewController(macros: macros, bluetoothManager: btManager)
            } catch {
                return
            }
        } else {
//            vc = UARTMacrosTableViewController(preset: UARTPreset.default, bluetoothManager: btManager)
        }
        
//        vc.macrosDelegate = self
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Saved macros" : "Create new one"
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        indexPath.section == 0 ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let macroName = macros[indexPath.row].name
        fatalError()
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

extension UARTMacrosList {
    private func loadMacrosList() -> [UARTMacro] {
        return []
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
        macros = loadMacrosList()
        tableView.reloadData()
    }
    
}
