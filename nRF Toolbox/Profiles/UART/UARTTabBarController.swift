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
    private var emptyView: UIView!
    let btManager = BluetoothManager()
    
    private lazy var uartViewController = UARTViewController1(bluetoothManager: btManager)
    private lazy var uartMacroViewController = UARTMacrosList(bluetoothManager: btManager, preset: .default)
    private lazy var uartLoggerViewController = UARTLoggerViewController(bluetoothManager: btManager)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = 0
        
        let viewControllers: [UIViewController] = [uartViewController, uartMacroViewController, uartLoggerViewController]
        
        setViewControllers(viewControllers, animated: true)
        
        tabBar.tintColor = .nordicBlue
        navigationItem.title = "UART"
        
        bufferView = view
        
        let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
            let scanner = PeripheralScanner(services: nil)
            let vc = ConnectionViewController(scanner: scanner)
            vc.delegate = self
            let nc = UINavigationController.nordicBranded(rootViewController: vc)
            self.present(nc, animated: true, completion: nil)
        })

        emptyView = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
        addEmptyView()
        btManager.delegate = self
    }
    
}

extension UARTTabBarController: BluetoothManagerDelegate {
    func didConnectPeripheral(deviceName aName: String?) {
        dismiss(animated: true) {
            self.uartViewController.deviceName = aName ?? ""
            self.emptyView.removeFromSuperview()
        }
    }
    
    func didDisconnectPeripheral() {
        addEmptyView()
    }
    
    func peripheralReady() {
        
    }
    
    func peripheralNotSupported() {
        view = emptyView
    }
}

extension UARTTabBarController {
    private func addEmptyView() {
        view.addSubview(emptyView)
        emptyView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        emptyView.translatesAutoresizingMaskIntoConstraints = false
    }
}

extension UARTTabBarController: ConnectionViewControllerDelegate {
    func connected(to peripheral: Peripheral) {
        btManager.connectPeripheral(peripheral: peripheral.peripheral)
    }
}
