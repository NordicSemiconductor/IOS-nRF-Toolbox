//
//  NORHKViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 06/03/2017.
//  Copyright © 2017 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import HomeKit

public let homeKitScannerSegue = "show_hk_scanner_view"
public let homeKitAccessorySegue = "show_hk_accessory_view"
class NORHKViewController: NORBaseViewController, HMHomeDelegate, HMHomeManagerDelegate, NORHKScannerDelegate, UITableViewDataSource, UITableViewDelegate {

    //MARK: - Properties
    private var accessoryBrowser: HMAccessoryBrowser!
    private var homeAccessories = [HMAccessory]()
    private var currentAccessory: HMAccessory?
    private var homeStore: NORHKHomeStore!

    //MARK: - Outlets and actions
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var changeHomeButton: UIButton!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var homeTitle: UILabel!
    @IBOutlet weak var accessoryTableView: UITableView!

    @IBAction func changeHomeButtonTapped(_ sender: Any) {
        handleChangeHomesButtonTapped()
    }
    @IBAction func aboutButtonTapped(_ sender: Any) {
        handleAboutButtonTapped()
    }

    @IBAction func connectionButtonTapped(_ sender: Any) {
        handleConnectionButtonTapped()
    }

    //MARK: - Implementation
    func handleChangeHomesButtonTapped() {
        if homeStore.homeManager.homes.count == 0 {
            //Create home, no homes available
            createPrimaryHome()
        } else {
            showHomeSwitcherUI()
        }
    }

    func handleAboutButtonTapped() {
        showAbout(message: NORAppUtilities.getHelpTextForService(service: .homekit))
    }
    func handleConnectionButtonTapped() {
        performSegue(withIdentifier: homeKitScannerSegue, sender: nil)
    }
    func getAccessoriesForHome(aHome: HMHome) -> [HMAccessory] {
        return aHome.accessories
    }

    func getPrimaryHome() -> HMHome? {
        return homeStore.homeManager.primaryHome
    }

    func createPrimaryHome() {
        homeStore.homeManager.addHome(withName: "My Home") { (aHome, anError) in
            if anError == nil {
                self.homeStore.homeManager.updatePrimaryHome(aHome!, completionHandler: { (anError) in
                    if let anError = anError {
                        self.connectionButton.isEnabled = false
                        print("Errow hile updating primary home! \(anError)")
                    } else {
                        print("Primary home upadted")
                        self.connectionButton.isEnabled = true
                    }
                })
                self.updateUIForHome(aHome: aHome!)
            } else {
                self.connectionButton.isEnabled = false
                let errorCode = (anError as! HMError).code
                if errorCode == .keychainSyncNotEnabled {
                    self.showError(message: "iCloud Keychain sync is disabled.\n\nTo use HomeKit please enable it form settings.", title: "iCloud Required")
                } else if errorCode == .homeAccessNotAuthorized {
                    self.showError(message: "Cannot create home, make sure nRF Toolbox has permission to access your home data.", title: "HomeKit Error")
                } else {
                    if anError?.localizedDescription != nil {
                        self.showError(message: (anError?.localizedDescription)!, title: "HomeKit Error")
                    } else {
                        self.showError(message: "An unknown error occured.", title: "HomeKit Error")
                    }
                }
            }
        }
    }
    
    func updateUIForHome(aHome: HMHome) {
        homeTitle.text = aHome.name.uppercased()
        homeAccessories = getAccessoriesForHome(aHome: aHome)
        accessoryTableView.reloadData()
    }

    func didSelectNewHome(_ aHome: HMHome) {
        homeStore.home = aHome
        homesDidChange()
    }

    func showHomeSwitcherUI() {
        let selectionAlertView = UIAlertController(title: "Select Home", message: "Select new home", preferredStyle: .actionSheet)
        for aHome in homeStore.homeManager.homes {
            selectionAlertView.addAction(UIAlertAction(title: aHome.name, style: .default) { (action) in
                self.didSelectNewHome(aHome)
            })
        }
        present(selectionAlertView, animated: true)
    }

    func pair(anAccessory: HMAccessory, withHome aHome: HMHome) {
        print(aHome, anAccessory)
        aHome.addAccessory(anAccessory) { error in
            if let error = error {
                print("Error in adding accessory \(error)")
            } else {
                print("Accessory is added successfully, attemting to add to main room")
            }
            
            //Browser needs to be released after adding accessory to the home.
            //Releasing the browser before adding the accessory will result in a HomeKit error 2 (Object not found.)
            //as the selected HMAccessory object becomes invalid.
            self.accessoryBrowser?.stopSearchingForNewAccessories()
            self.accessoryBrowser = nil
        }
    }

    //MARK: - HMHomeManagerDelegate
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if let primaryHome = manager.primaryHome {
            self.updateUIForHome(aHome: primaryHome)
            self.homeStore.home = primaryHome
        }
        switch manager.homes.count {
        case let count where count == 0:
            changeHomeButton.setTitle("Create home", for: .normal)
            changeHomeButton.isEnabled = true
        case let count where count == 1:
            changeHomeButton.setTitle("Change home", for: .normal)
            changeHomeButton.isEnabled = false
        default:
            changeHomeButton.setTitle("Change home", for: .normal)
            changeHomeButton.isEnabled = true
        }
        homesDidChange()
    }

    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        homeStore = NORHKHomeStore.sharedHomeStore
        homeStore.homeManager.delegate = self

        verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: -.pi / 2)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        homesDidChange()
    }

    func homesDidChange() {
        if let newHome = homeStore.home {
            updateUIForHome(aHome: newHome)
        } else {
            if let primaryHome = homeStore.homeManager.primaryHome {
                homeStore.home = primaryHome
                updateUIForHome(aHome: primaryHome)
                if homeStore.homeManager.homes.count > 1 {
                    changeHomeButton.setTitle("Change home", for: .normal)
                    changeHomeButton.isEnabled = true
                } else {
                    changeHomeButton.setTitle("Create home", for: .normal)
                    changeHomeButton.isEnabled = false
                }
            } else {
                changeHomeButton.setTitle("Create home", for: .normal)
                changeHomeButton.isEnabled = true
            }
        }
    }
    
    //MARK: - UITableViewDataSoruce
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "HKAccessoryCell", for: indexPath)
        aCell.textLabel?.text = homeAccessories[indexPath.row].name
        aCell.detailTextLabel?.text = homeAccessories[indexPath.row].category.localizedDescription
        return aCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homeAccessories.count
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let accessory = homeAccessories[indexPath.row]
        performSegue(withIdentifier: homeKitAccessorySegue, sender: accessory)
    }

    //MARK: - NORHKScannerDelegate
    func browser(aBrowser: HMAccessoryBrowser, didSelectAccessory anAccessory: HMAccessory) {
        accessoryBrowser = aBrowser
        currentAccessory = anAccessory
        accessoryBrowser.delegate = nil
        pair(anAccessory: anAccessory, withHome: homeStore.homeManager.primaryHome!)
    }

    //MARK: - Segue
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == homeKitAccessorySegue {
            if let _ = sender as? HMAccessory {
                return true
            } else {
                let alertView = UIAlertController(title: "No accessory", message: "The selected accessory was not found, please try scanning again and reselecting it.\r\nIf the problem persists, try unpairing that accessory and adding it again to your home.", preferredStyle: .alert)
                alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
                present(alertView, animated: true)
                return false
            }
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == homeKitScannerSegue {
            let navigationController = segue.destination as? UINavigationController
            let scannerView = navigationController?.topViewController as? NORHKScannerViewController
            scannerView?.delegate = self
        } else if segue.identifier == homeKitAccessorySegue {
            let accessoryView = segue.destination as? NORHKAccessoryViewController
            if let targetAccessory = sender as? HMAccessory {
                accessoryView?.setTargetAccessory(targetAccessory)
            } else {
                print("Error: No accessory found")
            }
        }
    }
}
