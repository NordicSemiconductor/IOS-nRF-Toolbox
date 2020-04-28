//
//  UARTTabBarController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 31/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth.CBPeripheral

protocol UARTRouter: class {
    func displayMacros(with preset: UARTPreset)
}

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
    
    private lazy var uartViewController = UARTViewController(bluetoothManager: btManager, uartRouter: self)
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

        let emptyView = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
        emptyView.actionButton.style = .mainAction
        self.emptyView = emptyView
        addEmptyView()
        btManager.delegate = self
        
        delegate = self

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
}

extension UARTTabBarController: BluetoothManagerDelegate {
    func didConnectPeripheral(deviceName aName: String?) {
        uartViewController.deviceName = aName ?? ""
        emptyView.removeFromSuperview()
    }
    
    func didDisconnectPeripheral() {
        addEmptyView()
    }
    
    func peripheralReady() {
        self.emptyView.removeFromSuperview()
    }
    
    func peripheralNotSupported() {
        view = emptyView
    }

    func requestedConnect(peripheral: CBPeripheral) {
        dismiss(animated: true) {
            (self.emptyView as? InfoActionView)?.buttonSettings = nil
            (self.emptyView as? InfoActionView)?.titleLabel.text = "Connecting..."
        }
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
    func requestConnection(to peripheral: Peripheral) {
        btManager.connectPeripheral(peripheral: peripheral.peripheral)
    }
}

extension UARTTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
        navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
    }
}

extension UARTTabBarController: UARTRouter {
    func displayMacros(with preset: UARTPreset) {
        let newMacroVC = UARTMacrosTableViewController(preset: preset, bluetoothManager: btManager)
        uartMacroViewController.navigationController?.pushViewController(newMacroVC, animated: false)
        newMacroVC.macrosDelegate = uartMacroViewController
        selectedViewController = uartMacroViewController        
    }
}
