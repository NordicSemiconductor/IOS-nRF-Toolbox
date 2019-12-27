//
//  SelectionsTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class SelectionsTableViewController: UITableViewController {
    
    private let items: [CustomStringConvertible]
    private let itemSelected: (Int) -> Void
    
    init(items: [CustomStringConvertible], selectedItem: Int, itemSelectionAction: @escaping (Int) -> Void) {
        self.items = items
        self.itemSelected = itemSelectionAction
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        Log(category: .ui, type: .fault).fault("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = items[indexPath.row].description
        cell.textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedIp = tableView.indexPathForSelectedRow {
            tableView.cellForRow(at: selectedIp)?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemSelected(indexPath.row)
    }
    
}
