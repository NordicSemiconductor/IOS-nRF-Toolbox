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
    
    init(bluetoothManager: BluetoothManager) {
        btManager = bluetoothManager
        super.init(nibName: "UARTLoggerViewController", bundle: .main)
        loadView()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UARTLoggerViewController {
    private func setupUI() {
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
        navigationItem.rightBarButtonItem = clearButton
        setupCloseButton()
        navigationItem.title = "Logger"
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