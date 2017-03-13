//
//  NORHKAccessoryViewController.swift
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

class NORHKAccessoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //MARK: - IBOutlets
    @IBOutlet weak var accessoryServicesTableView: UITableView!
    @IBOutlet weak var accessoryNameTitle: UILabel!
    @IBOutlet weak var homeNameTitle: UILabel!
    @IBOutlet weak var accessoryDFUSupportLabel: UILabel!
    @IBOutlet weak var accessoryCategoryLabel: UILabel!
    @IBOutlet weak var hardwareVersionLabel: UILabel!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var dfuModeButton: UIButton!
    
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

        guard dfuControlPointCharacteristic != nil else {
            UIAlertView(title: "Missing feature", message: "\"\(targetAccessory!.name)\" Does not seem to have the DFU control point characteristic, please try pairing it again or make sure it does support buttonless DFU.", delegate: nil, cancelButtonTitle: "Ok").show()
            print("DFU Control point charcateristic not found, please try again")
            return
        }
        
        dfuControlPointCharacteristic?.writeValue(0x01, completionHandler: { (error) in
            if error != nil {
                if (error as? HMError)?.code == HMError.readWriteFailure {
                    UIAlertView(title: "Restart initiating", message: "\"\(self.targetAccessory!.name)\" Should now disconnect and restart in DFU mode. to continue the flashing process please head towards the DFU option in the main menu, scan and find the new DFU peripheral and start the flashing process.", delegate: nil, cancelButtonTitle: "Ok").show()
                    print("Jump to bootloader")
                }
            }
        })
    }
    
    func ShowBootloaderWarning() {
        let controller = UIAlertController(title: "Accessory will restart", message: "Updating requires restarting this accessory into DFU mode.\r\nAfter restarting, open the DFU page to continue.", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Restart in DFU mode", style: .destructive, handler: { (anAction) in
            self.JumpToBootloaderMode()
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (anAction) in
            controller.dismiss(animated: true)
        }))
        
        self.present(controller, animated: true)
    }
    
    func showInfo(forCharactersitic aCharacteristic: HMCharacteristic) {
        var characteristicName = "Characteristic"
        if #available(iOS 9.0, *) {
            characteristicName = aCharacteristic.localizedDescription
        } else {
            characteristicName = aCharacteristic.metadata?.manufacturerDescription ?? characteristicName
        }

        let controller = UIAlertController(title: characteristicName, message: "Value: \(aCharacteristic.value ?? "Not available")", preferredStyle: .alert)
        if aCharacteristic.value != nil {
            controller.addAction(UIAlertAction(title: "Copy Value", style: .default, handler: { (anAction) in
                UIPasteboard.general.string = aCharacteristic.value as? String
            }))
        }
        controller.addAction(UIAlertAction(title: "Done", style: .default, handler: { (anAction) in
            controller.dismiss(animated: true)
        }))
        self.present(controller, animated: true)
    }

    func updateViewContents() {
        guard let targetAccessory = targetAccessory else {
            return
        }

        firmwareVersionLabel.text = "Reading..."
        hardwareVersionLabel.text = "Reading..."
        accessoryDFUSupportLabel.text = "Checking..."
        dfuModeButton.isEnabled = false
        accessoryNameTitle.text = targetAccessory.name
        homeNameTitle.text = targetAccessory.room?.name
        
        if #available(iOS 9.0, *) {
            accessoryCategoryLabel.text = targetAccessory.category.localizedDescription
        } else {
            accessoryCategoryLabel.text = "Unknown"
        }

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
        self.updateViewContents()
        accessoryServicesTableView.reloadData()
    }

    //MARK: - UITableViewDataSoruce
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 15, height: 30))
        headerView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 15, height: 30))
        headerView.addSubview(titleLabel)
        headerView.bringSubview(toFront: titleLabel)
        
        if #available(iOS 9.0, *) {
            titleLabel.text = targetAccessory?.services[section].localizedDescription
        } else {
            titleLabel.text = targetAccessory?.services[section].description
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "hk_characteristic_cell", for: indexPath)
        let aCharacteristic = targetAccessory?.services[indexPath.section].characteristics[indexPath.row] ?? nil
        
        if aCharacteristic != nil {
            if #available(iOS 9.0, *) {
                aCell.textLabel?.text = aCharacteristic?.localizedDescription ?? ""
            } else {
                // Fallback on earlier versions
                aCell.textLabel?.text = aCharacteristic?.metadata?.manufacturerDescription ?? ""
            }
        } else {
            aCell.textLabel?.text = "Unknown"
        }
        aCell.detailTextLabel?.text = ""
        return aCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return targetAccessory?.services[section].characteristics.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return targetAccessory?.services.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if #available(iOS 9.0, *) {
            return targetAccessory?.services[section].localizedDescription
        } else {
            return targetAccessory?.services[section].description
        }
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showInfo(forCharactersitic: targetAccessory!.services[indexPath.section].characteristics[indexPath.row])
    }
}
