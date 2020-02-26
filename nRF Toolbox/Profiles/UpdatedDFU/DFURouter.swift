//
//  DFURouter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol DFURouterType: class {
    
    func initialState() -> UIViewController
    
    func getStartViewController() -> DFUStartViewController
    
}

class DFURouter: DFURouterType {
    func getStartViewController() -> DFUStartViewController {
        return DFUStartViewController(router: self)
    }
    
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func initialState() -> UIViewController {
        let vc = getStartViewController()
        navigationController.viewControllers = [vc]
        return navigationController
    }
    
    
}
