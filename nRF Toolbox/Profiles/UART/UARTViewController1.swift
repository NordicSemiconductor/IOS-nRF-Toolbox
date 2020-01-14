//
//  UARTViewController1.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 30.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class UARTViewController1: UIViewController {

    let btManager = BluetoothManager()
    
    private lazy var connectBtn = UIBarButtonItem(title: "Connect", style: .done, target: self, action: #selector(openConnectorViewController))
    
    @IBOutlet private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btManager.delegate = self
        btManager.logger = self
        navigationItem.rightBarButtonItem = connectBtn
        
        let nib = UINib(nibName: "UARTActionCollectionViewCell", bundle: .main)
        collectionView.register(nib, forCellWithReuseIdentifier: "UARTActionCollectionViewCell")
    }
    
    @objc func openConnectorViewController() {
        let scanner = PeripheralScanner(services: nil)
        let connectionController = ConnectionViewController(scanner: scanner)
        connectionController.delegate = self

        let nc = UINavigationController.nordicBranded(rootViewController: connectionController)
        nc.modalPresentationStyle = .formSheet

        self.present(nc, animated: true, completion: nil)
    }
}

extension UARTViewController1: ConnectionViewControllerDelegate {
    func connected(to peripheral: Peripheral) {
        btManager.connectPeripheral(peripheral: peripheral.peripheral)
    }
}

extension UARTViewController1: BluetoothManagerDelegate {
    
    func didConnectPeripheral(deviceName aName: String?) {
        guard let presented = presentedViewController,
            let scannerNC = presented as? UINavigationController,
            let scanner = scannerNC.viewControllers.first as? ConnectionViewController else {
            return
        }
        
        scanner.dismiss(animated: true, completion: nil)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func didDisconnectPeripheral() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func peripheralReady() {
        
    }
    
    func peripheralNotSupported() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension UARTViewController1: Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) {
        Log(category: .ble, type: .debug).log(message: aMessage)
    }
}

extension UARTViewController1: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.size.width / 3
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}

extension UARTViewController1: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UARTActionCollectionViewCell", for: indexPath) as! UARTActionCollectionViewCell
        cell.title.text = "Test"
        cell.image.image = UIImage(named: "Repeat")
        return cell
    }
    
    
}
