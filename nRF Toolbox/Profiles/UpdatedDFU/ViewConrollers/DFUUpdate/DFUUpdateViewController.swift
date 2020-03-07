//
//  DFUUpdateViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 05/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class DFUUpdateViewController: UIViewController {
    @IBOutlet private var arrowImage: UIImageView!
    @IBOutlet private var loggerTableView: LoggerTableView!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var playPauseButton: UIButton!
    
    private let firmware: DFUFirmware!
    private let peripheral: Peripheral!
    private var dfuController: DFUServiceController?
    
    init(firmware: DFUFirmware, peripheral: Peripheral) {
        self.firmware = firmware
        self.peripheral = peripheral
        super.init(nibName: "DFUUpdateViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ firmware: DFUFirmware) {
        let initiator = DFUServiceInitiator()
        
        initiator.logger = loggerTableView
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        self.dfuController = initiator.with(firmware: firmware).start(target: peripheral.peripheral)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Update"
        update(self.firmware)
        playPauseButton.contentHorizontalAlignment = .fill
        playPauseButton.contentVerticalAlignment = .fill
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func startAnimating() {
        arrowImage.translatesAutoresizingMaskIntoConstraints = true
        
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [.repeat], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self.arrowImage.transform = CGAffineTransform(rotationAngle: .pi)
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.arrowImage.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.arrowImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        })
    }
    
    private func stopAnimation() {
        self.arrowImage.layer.removeAllAnimations()
    }
}

extension DFUUpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .uploading:
            startAnimating()
        case .aborted:
            stopAnimation()
        case .completed:
            stopAnimation()
        default:
            break
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print(message)
    }
    
    
}

extension DFUUpdateViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        progressView.progress = Float(progress) / 100.0
    }
    
    
}
