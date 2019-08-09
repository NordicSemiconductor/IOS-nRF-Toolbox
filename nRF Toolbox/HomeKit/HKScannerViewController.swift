//
//  HKScannerViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 07/03/2017.
//  Copyright © 2017 Nordic Semiconductor. All rights reserved.
//

import UIKit
import HomeKit

class HKScannerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, HMAccessoryBrowserDelegate {
    
    //MARK: - Outlets and Actions
    @IBOutlet weak var devicesTable: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    //MARK: - Scanner implementation
    public  var delegate: HKScannerDelegate?
    private var discoveredAccessories = [HMAccessory]()
    private let accessoryBrowser = HMAccessoryBrowser()
    
    private func startScanning() {
        accessoryBrowser.delegate = self
        accessoryBrowser.startSearchingForNewAccessories()
    }

    //MARK: - UIViewControllerw Flow
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let activityIndicatorView              = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.hidesWhenStopped = true
        navigationItem.rightBarButtonItem      = UIBarButtonItem(customView: activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        startScanning()
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedAccessory = discoveredAccessories[indexPath.row]
        delegate?.browser(aBrowser: accessoryBrowser, didSelectAccessory: selectedAccessory)
        self.dismiss(animated: true)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "HKAccessoryCell", for: indexPath)
        aCell.textLabel?.text = discoveredAccessories[indexPath.row].name
        aCell.detailTextLabel?.text = discoveredAccessories[indexPath.row].category.localizedDescription
        return aCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredAccessories.count
    }

    //MARK: - HMAccessoryBrowserDelegate
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        guard discoveredAccessories.contains(accessory) == false else {
            return
        }

        if discoveredAccessories.count == 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.emptyView.alpha = 0
            })
        }
        discoveredAccessories.append(accessory)
        devicesTable.reloadData()
    }
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        guard discoveredAccessories.contains(accessory) == true else {
            return
        }
        discoveredAccessories.remove(at: discoveredAccessories.firstIndex(of: accessory)!)
        devicesTable.reloadData()
    }
}
