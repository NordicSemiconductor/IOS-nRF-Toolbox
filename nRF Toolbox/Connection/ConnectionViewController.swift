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
    let scanner: PeripheralScanner
    
    weak var delegate: ConnectionViewControllerDelegate?
    
    init(scanner: PeripheralScanner) {
        self.scanner = scanner
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanner.scannerDelegate = self 
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
        self.scanner.refresh()
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanner.peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let p = scanner.peripherals[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = p.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .connecting = scanner.status {
            return
        }
        
        let peripheral = scanner.peripherals[indexPath.row]
        scanner.connect(to: peripheral)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        scanner.status.singleName
    }
}

extension ConnectionViewController: PeripheralScannerDelegate {
    func statusChanges(_ status: PeripheralScanner.Status) {
        let indexSet = IndexSet([0])
        tableView.reloadSections(indexSet, with: .none)
        
        if case .connecting(let p) = status {
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
