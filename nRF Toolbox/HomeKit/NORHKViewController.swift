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

class NORHKViewController: NORBaseViewController, HMHomeDelegate {
    
    //MARK: - Properties
    private var currentAccessory: HMAccessory?
    private var homeStore : NORHKHomeStore!
    
    //MARK: - Outlets and actions
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    
    @IBAction func aboutButtonTapped(_ sender: Any) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .homekit))
    }
    
    @IBAction func connectionButtonTapped(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: (CGFloat)(-M_PI_2))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if currentAccessory == nil {
            connectionButton.setTitle("CONNECT", for: .normal)
        } else {
            connectionButton.setTitle("DISCONNECT", for: .normal)
        }
    }
//    private func stopScan() {
//        
//    }
//    private func startScan() {
//        NORHKHomeStore.sharedHomeStore.home?.delegate = self
//        homeStore = NORHKHomeStore.sharedHomeStore
//        accessoryBrowser.delegate = self
//        accessoryBrowser.startSearchingForNewAccessories()
//    }
    
//    public func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
//        accessoryBrowser.stopSearchingForNewAccessories()
//        print("Found \(accessory.name)")
//        if #available(iOS 9.0, *) {
//            print("Type: \(accessory.category.localizedDescription)")
//        }
//    }
//    
//    public func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
//        print("Lost accessory \(accessory.name)")
//    }
}
