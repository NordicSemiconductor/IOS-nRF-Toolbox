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

protocol ConnectionViewControllerDelegate: AnyObject {
    func requestConnection(to peripheral: Peripheral)
}

class ConnectionViewController: UITableViewController {
    let scanner: PeripheralScanner
    
    weak var delegate: ConnectionViewControllerDelegate?
    
    init(scanner: PeripheralScanner, presentationType: PresentationType = .present) {
        self.scanner = scanner
        super.init(style: .grouped)
        setupNavigationAppearance(type: presentationType)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanner.scannerDelegate = self 
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.tableHeaderView = nil
        tableView.tableHeaderView = scanner.scanServices.flatMap { _ in
            let headerView = FilterSwitchView.instance()
            headerView.toggleAction = { [weak self] isOn in
                self?.scanner.serviceFilterEnabled = isOn
                self?.tableView.reloadData()
            }
            return headerView
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView?.frame.size.height = 44
    }
    
    @objc func close() {
        dismiss(animated: true)
    }
    
    @objc func refresh() {
        scanner.refresh()
        tableView.reloadData()
    }
    
    private func setupNavigationAppearance(type: PresentationType) {
        navigationItem.title = "Connect"
        
        let rightButton: UIBarButtonItem
        if #available(iOS 13.0, *) {
            rightButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        } else {
            rightButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        }
        navigationItem.rightBarButtonItem = rightButton
        
        guard case .present = type else { return }
        let leftButton: UIBarButtonItem
        if #available(iOS 13.0, *) {
            leftButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        } else {
            leftButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))
        }
        navigationItem.leftBarButtonItem = leftButton
    }
    
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
        delegate?.requestConnection(to: peripheral)
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
            delegate?.requestConnection(to: p)
        }
    }
    
    func newPeripherals(_ peripherals: [Peripheral], willBeAddedTo existing: [Peripheral]) {
        
    }
    
    func peripherals(_ peripherals: [Peripheral], addedTo old: [Peripheral]) {
        let insertedIndexPathes = peripherals.enumerated().map { IndexPath(row: old.count + $0.offset, section: 0) }
        tableView.insertRows(at: insertedIndexPathes, with: .automatic)
    }
}
