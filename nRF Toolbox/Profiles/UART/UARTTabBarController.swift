//
//  UARTTabBarController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 31/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTTabBarController: UITabBarController {
    
    private var bufferView: UIView!
    let btManager = BluetoothManager()
    
    init() {
        super.init(nibName: nil, bundle: .main)
        
        viewControllers = [
            UARTViewController1(bluetoothManager: btManager),
            UARTMacrosList(bluetoothManager: btManager, preset: .default),
            UARTLoggerViewController(bluetoothManager: btManager)
        ]
        
        bufferView = view
        
        let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
            self.view = self.bufferView
        })

        let notContent = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
        view = notContent
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
