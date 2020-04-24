//
//  ZephyrDFUTabBarViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ZephyrDFUTabBarViewController: UITabBarController {
    
    let logger = McuMgrLogObserver()
    
    private let router: ZephyrDFURouterType?
    private let data: Data
    private let peripheral: Peripheral
    private lazy var updateVC = ZephyrDFUTableViewController(data: data, peripheral: peripheral, router: self, logger: logger)
    private let loggerVC: LoggerTableViewController
    
    init(router: ZephyrDFURouterType, data: Data, peripheral: Peripheral) {
        self.loggerVC = LoggerTableViewController(observer: logger)
        self.router = router
        self.data = data
        self.peripheral = peripheral
        super.init(nibName: nil, bundle: nil)
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

extension ZephyrDFUTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
    }
}

extension ZephyrDFUTabBarViewController: DFUUpdateRouter {
    func showLogs() {
        selectedIndex = 1
    }
    
    func done() {
        router?.setInitialState()
    }
    
    
}
