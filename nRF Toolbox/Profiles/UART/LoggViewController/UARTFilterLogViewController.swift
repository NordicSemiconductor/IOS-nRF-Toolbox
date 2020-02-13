//
//  UARTFilterLogViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTFilterApplierDelegate: class {
    func setLevels(_ levels: [LOGLevel])
}

class UARTFilterLogViewController: UITableViewController, CloseButtonPresenter {
    private var selectedLevels: [LOGLevel]
    
    weak var filterDelegate: UARTFilterApplierDelegate?
    
    init(selectedLevels: [LOGLevel]) {
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
        
        LOGLevel.allCases.enumerated().forEach {
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
        section == 0 ? LOGLevel.allCases.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Select All"
            return cell
        }
        
        let level = LOGLevel.allCases[indexPath.row]
        let cell = tableView.dequeueCell(ofType: CheckmarkTableViewCell.self)
        let selected = selectedLevels.contains(level)
        cell.setSelected(selected, animated: false)
        cell.textLabel?.text = level.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationItem.rightBarButtonItem?.isEnabled = true
        guard indexPath.section == 1 else {
            selectedLevels.append(LOGLevel.allCases[indexPath.row])
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        for i in 0..<LOGLevel.allCases.count {
            let ip = IndexPath(row: i, section: 0)
            guard tableView.cellForRow(at: ip)?.isSelected == false else { continue }
            tableView.selectRow(at: ip, animated: false, scrollPosition: .none)
            selectedLevels.append(LOGLevel.allCases[i])
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        selectedLevels.removeAll { LOGLevel.allCases[indexPath.row] == $0 }
        
        var enabled = false
        for i in 0..<LOGLevel.allCases.count {
            if tableView.cellForRow(at: IndexPath(row: i, section: 0))?.isSelected == true {
                enabled = true
                break
            }
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
}
