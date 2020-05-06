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
import iOSDFULibrary

protocol UpgradeManager {
    func stop()
    func pause()
    func resume()
}

class UpgradeTableViewController<T: UpgradeManager>: UITableViewController {
    private (set) var headerView: DFUUpdateProgressView!
    let peripheral: Peripheral
    weak var router: DFUUpdateRouter?
    var manager: T?
    
    private (set) var controlSection = ControlSection()
    private (set) var stopSection = ControlSection()
    
    init(peripheral: Peripheral, router: DFUUpdateRouter?) {
        self.peripheral = peripheral
        self.headerView = DFUUpdateProgressView.instance()
        
        self.router = router
        
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        headerView.frame = CGRect(x: 0, y: -240, width: tableView.frame.width, height: 240)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Update"
        let tabBarItem = UITabBarItem(title: "Update", image: nil, tag: 1)
        if #available(iOS 13.0, *) {
            tabBarItem.image = UIImage(systemName: ModernIcon.arrow(.init(digit: 2))(.circlePath).name)
        } else {
            tabBarItem.image = UIImage(named: "update_ic")
        }
        
        self.tabBarItem = tabBarItem
        
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)

        tableView.contentInset.top = 240
        tableView.addSubview(headerView)
        
        controlSection.items = [.pause]
        stopSection.items = [.stop]
        
        controlSection.callback = { [unowned self] item in
            switch item.id {
            case .resume: self.resume()
            case .pause: self.pause()
            case .done: self.router?.done()
            case .retry: self.retry()
            case .showLog: self.router?.showLogs()
            case .stop: self.stop()
            default: break
            }
        }
        
        stopSection.callback = { [unowned self] _ in
            self.stop()
        }
        
        update()
    }
    
    func update() {
        
    }
    
    func stop() {
        manager?.pause()
        headerView.stopAnimating()
        
        let stopAction = UIAlertAction(title: "Stop", style: .destructive) { (_) in
            _ = self.manager?.stop()
            self.router?.done()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.manager?.resume()
            self.headerView.startAnimating()
        }
        
        let alert = UIAlertController(title: "Stop", message: "Are you sure you want to stop DFU process", preferredStyle: .alert)
        alert.addAction(cancel)
        alert.addAction(stopAction)
        
        present(alert, animated: true)
    }
    
    func retry() {
        update()
    }
    
    func pause() {
        manager?.pause()
        controlSection.items = [.resume]
        headerView.stopAnimating()
        tableView.reloadData()
    }
    
    func resume() {
        manager?.resume()
        controlSection.items = [.pause]
        headerView.startAnimating()
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        [controlSection, stopSection][section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        [controlSection, stopSection][indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        [controlSection, stopSection][indexPath.section].didSelectItem(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension DFUServiceController: UpgradeManager {
    func stop() {
        _ = abort()
    }
}

class DFUUpdateViewController: UpgradeTableViewController<DFUServiceController> {
    
    private let firmware: DFUFirmware!
    private let logger: LoggerDelegate
    private var serviceInitiator = DFUServiceInitiator()
    private var currentState: DFUState?
    
    init(firmware: DFUFirmware, peripheral: Peripheral, logger: LoggerDelegate, router: DFUUpdateRouter? = nil) {
        self.firmware = firmware
        self.logger = logger
        
        super.init(peripheral: peripheral, router: router)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        serviceInitiator.logger = logger
        serviceInitiator.delegate = self
        serviceInitiator.progressDelegate = self
        serviceInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        manager = serviceInitiator.with(firmware: firmware).start(target: peripheral.peripheral)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if case .some(let state) = currentState, state == .uploading {
            headerView.startAnimating()
        } else {
            headerView.stopAnimating()
        }
    }
}

extension DFUUpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        headerView.statusLabel.text = state.description()
        print(state.description())
        currentState = state
        
        headerView.stopAnimating()
        
        switch state {
        case .connecting:
            headerView.style = .update
            controlSection.items = []
            stopSection.items = [.stop]
        case .completed:
            headerView.style = .done
            controlSection.items = [.done]
            stopSection.items = []
        case .uploading:
            headerView.startAnimating()
            controlSection.items = [.pause]
            stopSection.items = [.stop]
        default:
            break
        }
        tableView.reloadData()
    }
    
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        headerView.style = .error
        headerView.statusLabel.text = message
        controlSection.items = [.retry, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
}

extension DFUUpdateViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        headerView.progressView.progress = Float(progress) / 100.0
        headerView.statusLabel.text = "Updating. Part \(part) of \(totalParts): \(progress)%"
        
        
    }
    
}
