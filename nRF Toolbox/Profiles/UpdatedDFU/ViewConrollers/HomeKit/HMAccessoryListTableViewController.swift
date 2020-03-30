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

class HMAccessoryListTableViewController: UIViewController, AlertPresenter {
    
    var hkManager: HMHomeManager!
    
    private let router: DFURouterType?
    
//    private var suggestedAccessories: [HMAccessory] = []
//    private var unsupportedAccessories: [HMAccessory] = []
    
    private var supportedSection = AccessoriesSection(sectionTitle: "Accessories with DFU Service", footer: "These accessories have DFU service and can be updated with Nordic DFU.", id: "supportedSection")
    private var unsupportedSection = AccessoriesSection(sectionTitle: "All other accessories", footer: nil, id: "unsupportedSection")
    
    var sections: [AccessoriesSection] {
        [supportedSection, unsupportedSection].filter { !$0.isHidden }
    }
    
    @IBOutlet private var tableView: UITableView!
    
    init(router: DFURouterType?) {
        self.router = router
        super.init(nibName: "HMAccessoryListTableViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hkManager = HMHomeManager()
        
        tableView.registerCellClass(cell: NordicBottomDetailsTableViewCell.self)
        
        navigationItem.title = "Accessories"
        
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAccessory))
        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(update))
        
        navigationItem.rightBarButtonItems = [addBtn, refreshBtn]
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: Remove it from viewDidAppear. That is workaround
        hkManager.delegate = self
    }
    
    func checkAvailability() {
        
        if #available(iOS 13.0, *) {
            switch hkManager.authorizationStatus {
            case .determined:
                let bSettings: InfoActionView.ButtonSettings = ("Settings", {
                    let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
                    let app = UIApplication.shared
                    app.open(url!, options: [:], completionHandler: nil)
                })

                let notContent = InfoActionView.instanceWithParams(message: "Access denied", buttonSettings: bSettings)
                notContent.actionButton.style = .mainAction
                notContent.messageLabel.text = "Open Settings to provide access to the Home Data"
                
                navigationItem.rightBarButtonItems = nil 
//                view = notContent
            case .restricted:
                break
            case .authorized:
                break
            default:
                break
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func addAccessory() {
        hkManager.homes.first?.addAndSetupAccessories(completionHandler: { [unowned self] (error) in
            if let e = error {
                self.displayErrorAlert(error: e)
                return
            }
        })
    }
    
    @objc private func update() {
        homeManagerDidUpdateHomes(hkManager)
    }
}

extension HMAccessoryListTableViewController: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        let (suggestedAccessories, unsupportedAccessories): ([HMAccessory], [HMAccessory]) = hkManager.homes.reduce([]) { $0 + $1.accessories }
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
        
        supportedSection.items = suggestedAccessories
        unsupportedSection.items = unsupportedAccessories
        
        guard suggestedAccessories.count + unsupportedAccessories.count > 0 else {
            let bSettings: InfoActionView.ButtonSettings = ("Add Accessory", {
                self.addAccessory()
            })

            let notContent = InfoActionView.instanceWithParams(message: "Add new HomeKit Accessory", buttonSettings: bSettings)
            notContent.messageLabel.text = "Currently there's no any HomeKit accessory. You can add the new one straight from nRF-ToolBox or from Home App."
            notContent.actionButton.style = .mainAction
            view = notContent
            return
        }
        
        view = tableView
        tableView.reloadData()
    }
    
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        
    }
    
    @available(iOS 13.0, *)
    func homeManager(_ manager: HMHomeManager, didReceiveAddAccessoryRequest request: HMAddAccessoryRequest) {
        
    }
    
    @available(iOS 13.0, *)
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        
    }
}

extension HMAccessoryListTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sections[section].numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accessory = sections[indexPath.section].items[indexPath.row]
        
        let homeName = hkManager.homes.first { $0.accessories.contains(accessory) }?.name
        let roomName = accessory.room?.name
        let detailsTitle = [roomName, homeName].compactMap { $0 }.joined(separator: " in ")
        
        let cell = tableView.dequeueCell(ofType: NordicBottomDetailsTableViewCell.self)
        cell.textLabel?.text = accessory.name
        cell.detailTextLabel?.text = detailsTitle
        
        return cell
    }
}

extension HMAccessoryListTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].sectionTitle
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].sectionFooter
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let accessory = sections[indexPath.section].items[indexPath.row]
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
}
