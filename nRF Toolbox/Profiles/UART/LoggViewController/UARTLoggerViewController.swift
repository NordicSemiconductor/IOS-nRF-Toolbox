//
//  UARTLoggerViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 28/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTLoggerViewController: UIViewController, CloseButtonPresenter {
    @IBOutlet private var loggerTableView: LoggerTableView!
    @IBOutlet private var commandTextField: UITextField!
    
    var logger: Logger { loggerTableView }
    private var btManager: BluetoothManager
    private var filterLogLevel: [LOGLevel] = LOGLevel.allCases
    
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
}

extension UARTLoggerViewController {
    private func setupUI() {
        setupCloseButton()
        navigationItem.title = "Logger"
        
        if #available(iOS 13.0, *) {
            let modern = ModernIcon.line(.horizontal)(.init(digit: 3))(.decrease)(.circle).image
            let filter = UIBarButtonItem(image: modern, style: .plain, target: self, action: #selector(openFilter))
            let clearItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(clear))
            navigationItem.rightBarButtonItems = [clearItem, filter]
        } else {
            let filter = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(openFilter))
            let clearItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
            navigationItem.rightBarButtonItems = [clearItem, filter]
        }
        
        btManager.logger = self.loggerTableView
    }
    
    @objc private func clear() {
        loggerTableView.clear()
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
    func setLevels(_ levels: [LOGLevel]) {
        print(levels)
        filterLogLevel = levels
        loggerTableView.filter = levels
        dismsiss()
    }
    
    
}
