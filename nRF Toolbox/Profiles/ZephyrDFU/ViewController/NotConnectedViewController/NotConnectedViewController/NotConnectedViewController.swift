//
//  EmptyViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NotConnectedViewController: UIViewController {
    
    weak var router: ZephyrDFURouterType?
    @IBOutlet private var button: NordicButton!
    
    init(router: ZephyrDFURouterType) {
        self.router = router
        super.init(nibName: "NotConnectedViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private var actionView: InfoActionView {
        view as! InfoActionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.style = .mainAction
        
        actionView.action = { [weak self] in
            self?.router?.goToPeripheralSelector(scanner: PeripheralScanner(services: nil), presentationType: .push, callback: { (preipheral) in
                self?.router?.goToFileSelector()
            })
        }

        navigationItem.title = "MCU Manager"
    }

}
