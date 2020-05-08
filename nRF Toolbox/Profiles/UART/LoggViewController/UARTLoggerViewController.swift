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

private extension UIImage {
    static func getFilterIcon(isFilled: Bool) -> UIImage? {
        if #available(iOS 13, *) {
            let icon = ModernIcon.line(.horizontal)(.init(digit: 3))(.decrease)(.circle)
            return (isFilled ? icon(.fill) : icon ).image
        } else {
            return UIImage(named: "baseline_filter_list_black_24pt")        
        }
    }
}

class UARTLoggerViewController: UIViewController, CloseButtonPresenter {
    @IBOutlet private var loggerTableView: LoggerTableView!
    @IBOutlet private var commandTextField: UITextField!
    
    var logger: Logger { loggerTableView }
    private var btManager: BluetoothManager
    private var filterLogLevel: [LogType] = LogType.allCases
    
    private lazy var filterBtn = UIBarButtonItem(image: UIImage.getFilterIcon(isFilled: false), style: .plain, target: self, action: #selector(openFilter))
    
    init(bluetoothManager: BluetoothManager) {
        btManager = bluetoothManager
        super.init(nibName: "UARTLoggerViewController", bundle: .main)
        loadView()
        setupUI()
        tabBarItem = UITabBarItem(title: "Logs", image: TabBarIcon.uartLogs.image, selectedImage: TabBarIcon.uartLogs.filledImage)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loggerTableView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func openFilter() {
        let vc = UARTFilterLogViewController(selectedLevels: filterLogLevel)
        vc.filterDelegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
        present(nc, animated: true)
    }
    
    func reset() {
        loggerTableView.reset()
    }
}

extension UARTLoggerViewController {
    private func setupUI() {
        setupCloseButton()
        navigationItem.title = "Logger"
        
        let trashImage: UIImage? = {
            if #available(iOS 13, *) {
                return ModernIcon.trash.image
            } else {
                return UIImage(named: "baseline_delete_outline_black_24pt")
            }
        }()
        let clearItem = UIBarButtonItem(image: trashImage, style: .plain, target: self, action: #selector(clear))
        navigationItem.rightBarButtonItems = [clearItem, filterBtn]
        
        btManager.logger = loggerTableView
    }
    
    @objc private func clear() {
        loggerTableView.reset()
    }
    
    
}

extension UARTLoggerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        defer {
            textField.resignFirstResponder()
        }
        guard let text = textField.text, !text.isEmpty else {
            return true
        }
        
        textField.text = ""
        btManager.send(text: text)
        return true 
    }
}

extension UARTLoggerViewController: UARTFilterApplierDelegate {
    func setLevels(_ levels: [LogType]) {
        print(levels)
        filterLogLevel = levels
        loggerTableView.filter = levels
        dismsiss()
        
        filterBtn.image = UIImage.getFilterIcon(isFilled: levels.count != LogType.allCases.count)
    }
    
    
}
