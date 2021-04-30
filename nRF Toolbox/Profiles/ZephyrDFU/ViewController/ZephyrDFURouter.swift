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

protocol ZephyrDFURouterType: AnyObject {
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
        let vc = ConnectionViewController(scanner: PeripheralScanner(services: nil), presentationType: presentationType)
        
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
