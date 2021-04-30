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
import CoreBluetooth.CBPeripheral

protocol UARTRouter: AnyObject {
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
    private var emptyView: InfoActionView!
    let btManager = BluetoothManager()
    private lazy var bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
        let scanner = PeripheralScanner(services: nil)
        let vc = ConnectionViewController(scanner: scanner)
        vc.delegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc)
        self.present(nc, animated: true, completion: nil)
    })
    
    private lazy var uartViewController = UARTViewController(bluetoothManager: btManager, uartRouter: self)
    private lazy var uartMacroViewController = UARTMacrosList(bluetoothManager: btManager, preset: .default)
    private lazy var uartLoggerViewController = UARTLoggerViewController(bluetoothManager: btManager)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewControllers: [UIViewController] = [uartViewController, uartMacroViewController, uartLoggerViewController]
        
        setViewControllers(viewControllers, animated: true)
        
        tabBar.tintColor = .nordicBlue
        navigationItem.title = "UART"
        
        bufferView = view

        let emptyView = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
        emptyView.actionButton.style = .mainAction
        self.emptyView = emptyView
        addEmptyView()
        btManager.delegate = self
        
        delegate = self

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        selectedIndex = 0
    }
    
}

extension UARTTabBarController: BluetoothManagerDelegate {
    func didConnectPeripheral(deviceName aName: String?) {
        uartViewController.deviceName = aName ?? ""
        emptyView.removeFromSuperview()
    }
    
    func didDisconnectPeripheral() {
        addEmptyView()
        self.emptyView.buttonSettings = bSettings
        self.emptyView.titleLabel.text = "Device is not connected"
        
        uartLoggerViewController.reset()
    }
    
    func peripheralReady() {
        self.emptyView.removeFromSuperview()
    }
    
    func peripheralNotSupported() {
        addEmptyView()
        self.emptyView.buttonSettings = bSettings
        self.emptyView.titleLabel.text = "Device is not supported"
    }

    func requestedConnect(peripheral: CBPeripheral) {
        dismiss(animated: true) {
            self.emptyView.buttonSettings = nil
            self.emptyView.titleLabel.text = "Connecting..."
            self.emptyView.buttonSettings = ("Cancel", { [unowned self] in
                self.btManager.cancelPeripheralConnection()
            })
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
        let newMacroVC = UARTMacrosTableViewController(preset: preset, bluetoothManager: btManager, presentationType: .present)
        let nc = UINavigationController.nordicBranded(rootViewController: newMacroVC, prefersLargeTitles: false)
        
        selectedViewController?.present(nc, animated: true, completion: nil)
        newMacroVC.macrosDelegate = uartMacroViewController
    }
}
