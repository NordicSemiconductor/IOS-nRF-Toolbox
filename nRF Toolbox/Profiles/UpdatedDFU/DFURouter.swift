//
//  DFURouter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary
import CoreBluetooth

enum PresentationType {
    case push, present
}

protocol DFURouterType: class {
    @discardableResult
    func initialState() -> UIViewController
    
    func getStartViewController() -> DFUStartViewController
    @discardableResult func goToBluetoothConnector(scanner: PeripheralScanner, presentationType: PresentationType, callback: @escaping (Peripheral) -> () ) -> ConnectionViewController
    @discardableResult func goToFileSelection() -> DFUFileSelector
    @discardableResult func goToFirmwareInfo(firmware: DFUFirmware) -> DFUFirmwareInfoViewController
    func goToUpdate(firmware: DFUFirmware, peripheral: Peripheral)
    @discardableResult
    func goToHMAccessoryList() -> HMAccessoryListTableViewController
}

class DFURouter: DFURouterType {
    func goToHMAccessoryList() -> HMAccessoryListTableViewController {
        let vc = HMAccessoryListTableViewController(router: self)
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    func goToUpdate(firmware: DFUFirmware, peripheral: Peripheral) {
        let vc = DFUUpdateTabBarViewController(router: self, firmware: firmware, peripheral: peripheral)
//        navigationController.setViewControllers([vc], animated: true)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private let btManager = DFUBluetoothManager()
    
    let navigationController: UINavigationController
    
    private var storedBluetoothCallback: ((Peripheral) -> ())!
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        btManager.callback = self
    }
    
    func goToFirmwareInfo(firmware: DFUFirmware) -> DFUFirmwareInfoViewController {
        let vc = DFUFirmwareInfoViewController(firmware: firmware, bluetoothManager: btManager, router: self)
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    @discardableResult
    func goToFileSelection() -> DFUFileSelector {
        let vc = DFUFileSelector(router: self)
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    @discardableResult
    func goToBluetoothConnector(scanner: PeripheralScanner, presentationType: PresentationType = .push, callback: @escaping (Peripheral) -> () ) -> ConnectionViewController {
        
        storedBluetoothCallback = callback
        
        let vc = ConnectionViewController(scanner: scanner, presentationType: presentationType)
        vc.delegate = btManager
        
        switch presentationType {
        case .present:
            let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
            navigationController.present(nc, animated: true)
        case .push:
            navigationController.pushViewController(vc, animated: true)
        }
        
        return vc
    }
    
    func getStartViewController() -> DFUStartViewController {
        return DFUStartViewController(router: self)
    }
    
    func initialState() -> UIViewController {
        let vc = getStartViewController()
        
//        let vc = DFUUpdateViewController()
        navigationController.viewControllers = [vc]
        return navigationController
    }
    
}

extension DFURouter: DFUConnectionCallback {
    func peripheralWasSelected(_ peripheral: Peripheral) {
        storedBluetoothCallback(peripheral)
    }
}
