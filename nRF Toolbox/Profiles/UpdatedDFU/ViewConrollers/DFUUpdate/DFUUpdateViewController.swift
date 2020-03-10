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
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var playPauseButton: UIButton!
    
    @IBOutlet private var stopBtn: NordicButton!
    @IBOutlet private var doneBtn: NordicButton!
    @IBOutlet private var retryBtn: NordicButton!
    @IBOutlet private var showLogBtn: NordicButton!
    
    @IBOutlet private var statusLabel: UILabel!
    
    private let firmware: DFUFirmware!
    private let peripheral: Peripheral!
    private let logger: LoggerDelegate
    weak var router: DFUUpdateRouter?
    private var dfuController: DFUServiceController?
    
    init(firmware: DFUFirmware, peripheral: Peripheral, logger: LoggerDelegate, router: DFUUpdateRouter? = nil) {
        self.firmware = firmware
        self.peripheral = peripheral
        self.logger = logger
        self.router = router
        super.init(nibName: "DFUUpdateViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ firmware: DFUFirmware) {
        let initiator = DFUServiceInitiator()
        
        initiator.logger = logger
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        self.dfuController = initiator.with(firmware: firmware).start(target: peripheral.peripheral)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Update"
        tabBarItem.title = "Update"
        if #available(iOS 13.0, *) {
            tabBarItem.image = UIImage(systemName: ModernIcon.arrow(.init(digit: 2))(.circlePath).name)
        } else {
            // Fallback on earlier versions
        }
        
        update(firmware)
        playPauseButton.tintColor = .nordicBlue
        playPauseButton.contentHorizontalAlignment = .fill
        playPauseButton.contentVerticalAlignment = .fill
        
        doneBtn.style = .mainAction
        stopBtn.style = .destructive
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction private func stop() {
        dfuController?.pause()
        
        let stopAction = UIAlertAction(title: "Stop", style: .destructive) { (_) in
            _ = self.dfuController?.abort()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dfuController?.resume()
        }
        
        let alert = UIAlertController(title: "Stop", message: "Are you sure you want to stop DFU process", preferredStyle: .alert)
        alert.addAction(cancel)
        alert.addAction(stopAction)
        
        present(alert, animated: true)
    }
    
    @IBAction private func retry() {
        update(firmware)
    }
    
    @IBAction private func showLog() {
        router?.showLogs()
    }
    
    @IBAction private func done() {
        router?.done()
    }
}

extension DFUUpdateViewController {
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
    
    /// Set buttons visible
    /// - Parameter hidden: tuple with hidden flags in the next order: stopBtn, doneBtn, retryBtn, showLogBtn
    private func setButtonHidden(_ hidden: (Bool, Bool, Bool, Bool)) {
        stopBtn.isHidden = hidden.0
        doneBtn.isHidden = hidden.1
        retryBtn.isHidden = hidden.2
        showLogBtn.isHidden = hidden.3
    }
}

extension DFUUpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        statusLabel.text = state.description()
        
        print(state.description())
        
        switch state {
        case .starting:
            retryBtn.isHidden = true
            setButtonHidden((false, true, true, true))
        case .uploading:
            startAnimating()
            setButtonHidden((false, true, true, true))
        case .aborted:
            setButtonHidden((true, false, false, false))
            stopAnimation()
        case .completed:
            setButtonHidden((true, false, true, false))
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
