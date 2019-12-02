//
//  DFUUpdateViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary
import CoreBluetooth

class DFUUpdateViewController: UIViewController {

    var activePeripheral: CBPeripheral!
    var firmware: DFUFirmware!
    
    @IBOutlet var phoneImage: ProgressImageView!
    @IBOutlet var deviceImage: ProgressImageView!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initiator = DFUServiceInitiator().with(firmware: firmware)
        initiator.progressDelegate = self
        initiator.delegate = self
        initiator.logger = self
        initiator.start(target: activePeripheral)
        
    }
    
}

extension DFUUpdateViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
//        let progress = Float(part) / Float(totalParts)
        self.deviceImage.progress = Float(progress) / 100
        self.phoneImage.progress = 1 - Float(progress) / 100
    }
}

extension DFUUpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        Log(category: .ble, type: .debug).log(message: "DFU Status: \(state.description())")
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        Log(category: .ble, type: .error).log(message: "DFU Error: \(message)")
    }
}

extension DFUUpdateViewController: LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        textView.text += ("\n" + message)
//        textView.contentOffset = 
    }
}
