//
//  HKAccessoryViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 08/03/2017.
//  Copyright © 2017 Nordic Semiconductor. All rights reserved.
//

import UIKit
import HomeKit

//Identifiers
let dfuServiceIdentifier            = "00001530-1212-EFDE-1523-785FEABCD123"
let dfuControlPointIdentifier       = "00001531-1212-EFDE-1523-785FEABCD123"
let accessoryInformationIdentifier  = "0000003E-0000-1000-8000-0026BB765291"
let hwVersionIdentifier             = "00000053-0000-1000-8000-0026BB765291"
let fwVersionIdentifier             = "00000052-0000-1000-8000-0026BB765291"

class HKAccessoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //MARK: - IBOutlets
    @IBOutlet weak var accessoryServicesTableView: UITableView!
    @IBOutlet weak var homeNameTitle: UILabel!
    @IBOutlet weak var accessoryDFUSupportLabel: UILabel!
    @IBOutlet weak var accessoryCategoryLabel: UILabel!
    @IBOutlet weak var hardwareVersionLabel: UILabel!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var dfuModeButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func dfuButtonTapped(_ sender: Any) {
        ShowBootloaderWarning()
    }

    //MARK: - Class Properties
    private var targetAccessory: HMAccessory?
    private var hasDFUControlPoint: Bool = false
    private var dfuControlPointCharacteristic: HMCharacteristic?
    
    //MARK: - Implementation
    public func setTargetAccessory(_ anAccessory: HMAccessory) {
        targetAccessory = anAccessory
    }
    
    func JumpToBootloaderMode() {
        var commandCompleted = false
        
        guard dfuControlPointCharacteristic != nil else {
            let alertView = UIAlertController(title: "Missing feature", message: "\"\(targetAccessory!.name)\" Does not seem to have the DFU control point characteristic, please try pairing it again or make sure it does support buttonless DFU.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alertView, animated: true)
            return
        }
        
        activityIndicator.startAnimating()
        //Display wait message after 500ms, to prevent multiple windows in case the completion
        //Alert has already been displayed.
        let waitAlertView = UIAlertController(title: "Please wait...", message: "Sending DFU command to target accessory.\n\nThis might take a few seconds if the accessory is unreachable.", preferredStyle: .alert)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if commandCompleted == false {
                self.present(waitAlertView, animated: true)
            }
        }
        
        dfuControlPointCharacteristic?.writeValue(0x01, completionHandler: { (error) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                commandCompleted = true
                waitAlertView.dismiss(animated: true)
                if error != nil {
                    self.showFailAlertWithFailMessage((error as! HMError).localizedDescription)
                } else {
                    self.showRestartAlertWithAccessoryName(self.targetAccessory!.name)
                }
            }
        })
    }
    
    func showFailAlertWithFailMessage(_ aMessage: String) {
        let alertView = UIAlertController(title: "HomeKit error", message: aMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertView, animated: true)
    }
    
    func showRestartAlertWithAccessoryName(_ aName: String) {
        let alertView = UIAlertController(title: "Restart initiating", message: "\"\(aName)\" should now disconnect and restart in DFU mode.\n\nTo continue the flashing process please head towards the DFU option in the main menu, scan and find the new DFU peripheral and start the flashing process.", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertView, animated: true)
    }

    func ShowBootloaderWarning() {
        let controller = UIAlertController(title: "Accessory will restart", message: "Updating requires restarting this accessory into DFU mode.\r\nAfter restarting, open the DFU page to continue.", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Restart in DFU mode", style: .destructive) { _ in
            self.JumpToBootloaderMode()
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(controller, animated: true)
    }

    func updateViewContents() {
        guard let targetAccessory = targetAccessory else {
            return
        }

        firmwareVersionLabel.text = "Reading..."
        hardwareVersionLabel.text = "Reading..."
        accessoryDFUSupportLabel.text = "Checking..."
        dfuModeButton.isEnabled = false
        title = targetAccessory.name
        homeNameTitle.text = targetAccessory.room?.name ?? "Unknown"
        
        accessoryCategoryLabel.text = targetAccessory.category.localizedDescription
        
        for aService in targetAccessory.services {
            if aService.serviceType == accessoryInformationIdentifier {
                for aCharacteristic in aService.characteristics {
                    if aCharacteristic.characteristicType == fwVersionIdentifier {
                        aCharacteristic.readValue(completionHandler: { (error) in
                            DispatchQueue.main.async {
                                if error == nil {
                                    self.firmwareVersionLabel.text = aCharacteristic.value as? String ?? "N/A"
                                } else {
                                    self.firmwareVersionLabel.text = "N/A"
                                }
                            }
                        })
                    } else if aCharacteristic.characteristicType == hwVersionIdentifier {
                        aCharacteristic.readValue(completionHandler: { (error) in
                            DispatchQueue.main.async {
                                if error == nil {
                                    self.hardwareVersionLabel.text = aCharacteristic.value as? String ?? "N/A"
                                } else {
                                    self.hardwareVersionLabel.text = "N/A"
                                }
                            }
                        })
                    }
                }
            } else if aService.serviceType == dfuServiceIdentifier {
                for aCharacteristic in aService.characteristics {
                    if aCharacteristic.characteristicType == dfuControlPointIdentifier {
                        dfuControlPointCharacteristic = aCharacteristic
                        hasDFUControlPoint = true
                    }
                }
            }
        }

        if hasDFUControlPoint == true {
            accessoryDFUSupportLabel.text = "Yes"
            dfuModeButton.isEnabled = true
        } else {
            accessoryDFUSupportLabel.text = "No"
            dfuModeButton.isEnabled = false
        }
    }

    //MARK: - UIVIewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.stopAnimating()
        updateViewContents()
        accessoryServicesTableView.reloadData()
    }

    //MARK: - UITableViewDataSoruce
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 15, height: 30))
        headerView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 15, height: 30))
        headerView.addSubview(titleLabel)
        headerView.bringSubviewToFront(titleLabel)
        
        titleLabel.text = targetAccessory?.services[section].localizedDescription
        
        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "hk_characteristic_cell", for: indexPath)
        let aCharacteristic = targetAccessory?.services[indexPath.section].characteristics[indexPath.row] ?? nil
        
        if aCharacteristic != nil {
            aCell.textLabel?.text = aCharacteristic?.localizedDescription ?? ""
        } else {
            aCell.textLabel?.text = "Unknown"
        }
        aCell.detailTextLabel?.text = aCharacteristic?.value as? String ?? "Unknown"
        return aCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return targetAccessory?.services[section].characteristics.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return targetAccessory?.services.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return targetAccessory?.services[section].localizedDescription
    }
    
}
