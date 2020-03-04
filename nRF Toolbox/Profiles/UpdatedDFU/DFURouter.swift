//
//  DFURouter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

enum PresentationType {
    case push, present
}

protocol DFURouterType: class {
    func initialState() -> UIViewController
    
    func getStartViewController() -> DFUStartViewController
    @discardableResult func goToBluetoothConnector(scanner: PeripheralScanner, presentationType: PresentationType, callback: @escaping (Peripheral) -> () ) -> ConnectionViewController
    @discardableResult func goToFileSelection() -> DFUFileSelector
    @discardableResult func goToFirmwareInfo(firmware: DFUFirmware) -> DFUFirmwareInfoViewController
}

class DFURouter: DFURouterType {
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
        navigationController.viewControllers = [vc]
        return navigationController
    }
    
}

extension DFURouter: DFUConnectionCallback {
    func peripheralWasSelected(_ peripheral: Peripheral) {
        storedBluetoothCallback(peripheral)
    }
}
