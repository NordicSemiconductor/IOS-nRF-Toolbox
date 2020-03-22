//
//  DFUStartViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUStartViewController: UIViewController {
    
    @IBOutlet private var connectButton: NordicButton!
    @IBOutlet private var accessoriesButton: NordicButton!
    
    private let router: DFURouterType
    
    init(router: DFURouterType) {
        self.router = router
        super.init(nibName: "DFUStartViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "DFU"
        
        connectButton.style = .mainAction
        accessoriesButton.style = .mainAction
    }

    @IBAction func openBluetoothConnector() {
        router.goToBluetoothConnector(scanner: PeripheralScanner(services: []), presentationType: .push) { [weak self] (p) in
            self?.router.goToFileSelection()
        }
    }
    
    @IBAction func openHomeAccessory() {
        router.goToHMAccessoryList()
    }
}

