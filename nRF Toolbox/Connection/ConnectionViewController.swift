//
//  ConnectionViewController.swift
//  Scanner
//
//  Created by Nick Kibysh on 02/12/2019.
//  Copyright © 2019 Nick Kibysh. All rights reserved.
//

import UIKit

protocol ConnectionViewControllerDelegate: class {
    func connected(to peripheral: Peripheral)
}

class ConnectionViewController: UITableViewController {
    let connectionManager = ConnectionManager()
    
    weak var delegate: ConnectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectionManager.delegate = self 
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        navigationItem.title = "Correct"
        
        var leftButton: UIBarButtonItem
        var rightButton: UIBarButtonItem
        if #available(iOS 13.0, *) {
            leftButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
            rightButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        } else {
            leftButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))
            rightButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        }
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    @objc func refresh() {
        self.connectionManager.refresh()
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionManager.peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let p = connectionManager.peripherals[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = p.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .connecting = connectionManager.status {
            return
        }
        
        let peripheral = connectionManager.peripherals[indexPath.row]
        connectionManager.connect(to: peripheral)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        connectionManager.status.singleName
    }
}

extension ConnectionViewController: ConnectionManagerDelegate {
    func statusChanges(_ status: ConnectionManager.Status) {
        let indexSet = IndexSet([0])
        tableView.reloadSections(indexSet, with: .none)
        
        if case .connected(let p) = status {
            self.delegate?.connected(to: p)
        }
    }
    
    func newPeripherals(_ peripherals: [Peripheral], willBeAddedTo existing: [Peripheral]) {
        
    }
    
    func peripherals(_ peripherals: [Peripheral], addedTo old: [Peripheral]) {
        let insertedIndexPathes = peripherals.enumerated().map { IndexPath(row: old.count + $0.offset, section: 0) }
        self.tableView.insertRows(at: insertedIndexPathes, with: .automatic)
    }
}
