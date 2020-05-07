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

protocol UARTFilterApplierDelegate: class {
    func setLevels(_ levels: [LogType])
}

class UARTFilterLogViewController: UITableViewController, CloseButtonPresenter {
    private var selectedLevels: [LogType]
    
    weak var filterDelegate: UARTFilterApplierDelegate?
    
    init(selectedLevels: [LogType]) {
        self.selectedLevels = selectedLevels
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellClass(cell: CheckmarkTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        tableView.allowsMultipleSelection = true
        
        navigationItem.title = "Filter"
        setupCloseButton()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        LogType.allCases.enumerated().forEach {
            if selectedLevels.contains($0.element) {
                tableView.selectRow(at: IndexPath(row: $0.offset, section: 0), animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: IndexPath(row: $0.offset, section: 0), animated: false)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func save() {
        filterDelegate?.setLevels(selectedLevels)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? LogType.allCases.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Select All"
            return cell
        }
        
        let level = LogType.allCases[indexPath.row]
        let cell = tableView.dequeueCell(ofType: CheckmarkTableViewCell.self)
        let selected = selectedLevels.contains(level)
        cell.setSelected(selected, animated: false)
        cell.textLabel?.text = level.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            selectedLevels = LogType.allCases
            self.tableView(tableView, setSelection: true)
            return
        }
        
        self.tableView(tableView, setSelection: false)
        selectedLevels = selectedTypes(start: indexPath, tableView: tableView)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        
        self.tableView(tableView, setSelection: false)
        selectedLevels = selectedTypes(start: indexPath, tableView: tableView)
    }
}

extension UARTFilterLogViewController {
    private func selectedTypes(start indexPath: IndexPath, tableView: UITableView) -> [LogType] {
        let selectedSequence = sequence(first: indexPath) { (ip) -> IndexPath? in
            guard ip.row < LogType.allCases.count - 1 else { return nil }
            return IndexPath(item: ip.row + 1, section: ip.section)
        }
        
        selectedSequence.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }
        
        return selectedSequence.map {
            LogType.allCases[$0.row]
        }
    }
    
    private func tableView(_ tableView: UITableView, setSelection selection: Bool) {
        sequence(first: IndexPath(row: 0, section: 0)) { (ip) -> IndexPath? in
            let next = IndexPath(row: ip.row + 1, section: ip.section)
            guard next.row < LogType.allCases.count else { return nil }
            return next
        }
        .forEach {
            if selection {
                tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: $0, animated: false)
            }
        }
    }
}
