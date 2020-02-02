//
//  UARTTabBarController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 31/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct TabBarIcon {
    private var imageName: String
    private var modernIcon: ModernIcon
    
    init(imageName: String, modernIcon: ModernIcon) {
        self.imageName = imageName
        self.modernIcon = modernIcon
    }
    
    var image: UIImage {
        if #available(iOS 13, *) {
            return modernIcon.image ?? UIImage()
        } else {
            return UIImage(named: imageName) ?? UIImage()
        }
    }
    
    var filledImage: UIImage {
        if #available(iOS 13, *) {
            return modernIcon.add(.fill).image ?? modernIcon.image ?? UIImage()
        } else {
            return image
        }
    }
    
    static let uartPreset = TabBarIcon(imageName: "uart_preset", modernIcon: ModernIcon.circle.add(.grid).add(.threeXthree))
    static let uartMacros = TabBarIcon(imageName: "uart_macros", modernIcon: ModernIcon.bolt)
    static let uartLogs = TabBarIcon(imageName: "uart_log", modernIcon: ModernIcon.list.add(.dash))
}

class UARTTabBarController: UITabBarController {
    
    private var bufferView: UIView!
    let btManager = BluetoothManager()
    
    init() {
        super.init(nibName: nil, bundle: .main)
        
        tabBar.tintColor = .nordicBlue
        viewControllers = [
            UARTViewController1(bluetoothManager: btManager),
            UARTMacrosList(bluetoothManager: btManager, preset: .default),
            UARTLoggerViewController(bluetoothManager: btManager)
        ]
        
        navigationItem.title = "UART"
        
        /*
        bufferView = view
        
        let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
            self.view = self.bufferView
        })

        let notContent = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
        view = notContent
        */
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = 0
    }
    
}
