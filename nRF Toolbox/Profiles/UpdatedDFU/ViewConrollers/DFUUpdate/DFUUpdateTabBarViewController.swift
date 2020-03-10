//
//  DFUUpdateTabBarViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

protocol DFUUpdateRouter: class {
    func showLogs()
    func done()
}

class DFUUpdateTabBarViewController: UITabBarController {
    let logger = LoggObserver()
    
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
