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

import Core
import UART
import UIKit
import CoreBluetooth.CBPeripheral
import Intents

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

class UARTTabBarController: UITabBarController, AlertPresenter {
    let btManager = BluetoothManager.shared
    let presetManager = PresetManager()
    let macrosManager = MacrosManager()
    
    private lazy var bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
        let scanner = PeripheralScanner(services: nil)
        let vc = ConnectionViewController(scanner: scanner)
        vc.delegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc)
        self.present(nc, animated: true, completion: nil)
    })
    
    private lazy var uartViewController = UARTViewController(bluetoothManager: btManager, presetManager: self.presetManager, macrosManager: self.macrosManager)
    private lazy var uartLoggerViewController = UARTLoggerViewController(bluetoothManager: btManager)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewControllers: [UIViewController] = [uartViewController, uartLoggerViewController, UARTMacrosCollectionViewController()]
        
        setViewControllers(viewControllers, animated: true)
        
        tabBar.tintColor = .nordicBlue
        navigationItem.title = "UART"

        btManager.delegate = self
        
        delegate = self

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        selectedIndex = 0
    }
    
}

extension UARTTabBarController: BluetoothManagerDelegate {
    func failed(with error: Error) {
        guard let e = error as? BluetoothManager.Errors else {
            displayErrorAlert(error: error)
            return
        }

        switch e {
        case .noDeviceConnected:
            bSettings.1()
        case .cannotFindPeripheral:
            break
        }
    }
    
    func requestDeviceList() {
        bSettings.1()
    }

    func didConnectPeripheral(deviceName aName: String?) {
        // TODO: Change device view mode
        uartViewController.deviceName = aName ?? ""
    }
    
    func didDisconnectPeripheral() {
        // TODO: should we reset logView?
//        uartLoggerViewController.reset()
    }
    
    func peripheralReady() {
        // TODO: Device view mode should be changed
    }
    
    func peripheralNotSupported() {
        // TODO: Display notification
//        self.emptyView.titleLabel.text = "Device is not supported"
    }

    func requestedConnect(peripheral: CBPeripheral) {
        dismiss(animated: true) {
            // TODO: change device view
        }
    }
}

extension UARTTabBarController {
    private func setDisconnected() {

    }

    private func requestSiriAuth() {
        
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
