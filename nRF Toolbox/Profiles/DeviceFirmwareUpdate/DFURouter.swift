/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
    @discardableResult func goToFileSelection() -> DFUFileSelectorViewController
    @discardableResult func goToFirmwareInfo(firmware: DFUFirmware) -> DFUFirmwareInfoViewController
    func goToUpdate(firmware: DFUFirmware, peripheral: Peripheral)
    @discardableResult func goToHMAccessoryList() -> HMAccessoryListTableViewController
}

class DFURouter: DFURouterType {
    func goToHMAccessoryList() -> HMAccessoryListTableViewController {
        let vc = HMAccessoryListTableViewController(router: self)
        navigationController.pushViewController(vc, animated: true)
        return vc
    }
    
    func goToUpdate(firmware: DFUFirmware, peripheral: Peripheral) {
        let vc = DFUUpdateTabBarViewController(router: self, firmware: firmware, peripheral: peripheral)
        navigationController.setViewControllers([vc], animated: true)
    }
    
    private let btManager = PeripheralHolder()
    
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
    func goToFileSelection() -> DFUFileSelectorViewController {
        let vc = DFUFileSelectorViewController(router: self, documentPicker: DFUDocumentPicker())
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
        DFUStartViewController(router: self)
    }
    
    func initialState() -> UIViewController {
        let vc = getStartViewController()
        navigationController.viewControllers = [vc]
        return navigationController
    }
    
}

extension DFURouter: PeripheralConnectionCallback {
    func peripheralWasSelected(_ peripheral: Peripheral) {
        storedBluetoothCallback(peripheral)
    }
}
