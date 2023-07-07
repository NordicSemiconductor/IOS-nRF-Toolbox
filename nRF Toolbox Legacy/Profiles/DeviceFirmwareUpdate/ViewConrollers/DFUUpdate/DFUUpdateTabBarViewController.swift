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
import NordicDFU

protocol DFUUpdateRouter: AnyObject {
    func showLogs()
    func done()
}

class DFUUpdateTabBarViewController: UITabBarController {
    let logger = DFULogObserver()
    
    private let router: DFURouterType
    private let updateVC: DFUUpdateViewController
    private let loggerVC: LoggerTableViewController
    
    init(router: DFURouterType, firmware: DFUFirmware, peripheral: Peripheral) {
        self.router = router
        
        self.updateVC = DFUUpdateViewController(firmware: firmware, peripheral: peripheral, logger: logger)
        self.loggerVC = LoggerTableViewController(observer: logger)
        
        super.init(nibName: nil, bundle: nil)
        
        updateVC.router = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .nordicBlue
        navigationItem.title = "Update"
        setViewControllers([updateVC, loggerVC], animated: true)
        delegate = self
        selectedIndex = 0
    }
}

extension DFUUpdateTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
    }
}

extension DFUUpdateTabBarViewController: DFUUpdateRouter {
    func showLogs() {
        selectedIndex = 1
    }
    
    func done() {
        router.initialState()
    }
    
    
}
