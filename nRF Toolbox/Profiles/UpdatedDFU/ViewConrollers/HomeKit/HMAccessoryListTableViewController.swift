//
//  HMAccessoryListTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import HomeKit

let dfuServiceIdentifier = "00001530-1212-EFDE-1523-785FEABCD123"
//let dfuControlPointIdentifier = "00001531-1212-EFDE-1523-785FEABCD123"

class HMAccessoryListTableViewController: UITableViewController, AlertPresenter {
    
    let hkManager = HMHomeManager()
    
    private let router: DFURouterType?
    
    private var suggestedAccessories: [HMAccessory] = []
    private var unsupportedAccessories: [HMAccessory] = []
    
    init(router: DFURouterType?) {
        self.router = router
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellClass(cell: NordicBottomDetailsTableViewCell.self)
        hkManager.delegate = self
        
        navigationItem.title = "Accessories"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAccessory))
    }
    
    @objc func addAccessory() {
        hkManager.homes.first?.addAndSetupAccessories(completionHandler: { [unowned self] (error) in
            if let e = error {
                self.displayErrorAlert(error: e)
                return
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return [suggestedAccessories, unsupportedAccessories][section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accessory = [suggestedAccessories, unsupportedAccessories][indexPath.section][indexPath.row]
        
        let homeName = hkManager.homes.first { $0.accessories.contains(accessory) }?.name
        let roomName = accessory.room?.name
        let detailsTitle = [roomName, homeName].compactMap { $0 }.joined(separator: " in ")
        
        let cell = tableView.dequeueCell(ofType: NordicBottomDetailsTableViewCell.self)
        cell.textLabel?.text = accessory.name
        cell.detailTextLabel?.text = detailsTitle
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Accessories with DFU Service" : "All other accessories"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "These accessories have DFU service and can be updated with Nordic DFU." : nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let accessory = [suggestedAccessories, unsupportedAccessories][indexPath.section][indexPath.row]
        guard let service = accessory.services.first (where: { $0.serviceType == dfuServiceIdentifier }) else { return }
        guard let characteristic = service.characteristics.first(where: { $0.characteristicType == dfuControlPointIdentifier }) else { return }
        characteristic.writeValue(0x01) { (error) in
            if let e = error {
                self.displayErrorAlert(error: e)
                return
            }
            
            self.router?.goToBluetoothConnector(scanner: PeripheralScanner(services: []), presentationType: .push, callback: { (p) in
                self.router?.goToFileSelection()
            })
            
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HMAccessoryListTableViewController: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        (suggestedAccessories, unsupportedAccessories) = hkManager.homes.reduce([]) { $0 + $1.accessories }
            .reduce(([], [])) {
                var supported = $0.0
                var unsupported = $0.1
                if $1.services.contains(where: { $0.serviceType == dfuServiceIdentifier }) {
                    supported.append($1)
                } else {
                    unsupported.append($1)
                }
                return (supported, unsupported)
        }
        tableView.reloadData()
    }
}
