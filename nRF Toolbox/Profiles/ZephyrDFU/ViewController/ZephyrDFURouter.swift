//
//  ZephyrDFURouter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol ZephyrDFURouterType: class {
    @discardableResult func setInitialState() -> UIViewController
    @discardableResult func goToPeripheralSelector(scanner: PeripheralScanner, presentationType: PresentationType, callback: @escaping (Peripheral) -> ()) -> ConnectionViewController
    @discardableResult func goToFileSelector() -> ZephyrFileSelector
    @discardableResult func goToUpdateScreen(data: Data) -> ZephyrDFUTabBarViewController
}

class ZephyrDFURouter: ZephyrDFURouterType {
    func goToFileSelector() -> ZephyrFileSelector {
        let vc = ZephyrFileSelector(router: self, documentPicker: ZephyrDFUDocumentPicker())
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    func goToUpdateScreen(data: Data) -> ZephyrDFUTabBarViewController {
        let vc = ZephyrDFUTabBarViewController(router: self, data: data, peripheral: btManager.peripheral)
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    let navigationController: UINavigationController
    private var storedBluetoothCallback: ((Peripheral) -> ())!
    private let btManager = PeripheralHolder()
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        btManager.callback = self
    }
    
    func setInitialState() -> UIViewController {
        let vc = NotConnectedViewController(router: self)
        
        navigationController.viewControllers = [vc]
        return navigationController
    }
    
    func goToPeripheralSelector(scanner: PeripheralScanner, presentationType: PresentationType = .push, callback: @escaping (Peripheral) -> ()) -> ConnectionViewController {
        let vc = ConnectionViewController(scanner: PeripheralScanner(services: nil))
        
        storedBluetoothCallback = callback
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
    
}

extension ZephyrDFURouter: PeripheralConnectionCallback {
    func peripheralWasSelected(_ peripheral: Peripheral) {
        storedBluetoothCallback(peripheral)
    }
    
    
}
