//
//  NORLoggerViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORLogViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, NORLogger{
    
    //MARK: - Properties
    var bluetoothManager : NORBluetoothManager?
    var logItems         : NSMutableArray
    
    //MARK: - View Outlets
    @IBOutlet weak var displayLogTextTable : UITableView!
    @IBOutlet weak var commandTextField : UITextField!

    //MARK: - View Actions
    
    //MARK: - UIViewDelegate
    required init?(coder aDecoder: NSCoder) {
        logItems = NSMutableArray()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLogTextTable.delegate = self
        displayLogTextTable.dataSource = self
        displayLogTextTable.rowHeight = UITableViewAutomaticDimension
        displayLogTextTable.estimatedRowHeight = 25
        displayLogTextTable.reloadData()
        commandTextField.placeholder = "No UART connected"
        commandTextField.delegate = self
    }
    
    func clearLog() {
        logItems.removeAllObjects()
        displayLogTextTable?.reloadData() // The table may not be initialized here
    }
    
    //MARK: - NORLoggerViewController implementation
    func getCurrentTime() -> String {
        let now = Date()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = outputFormatter.string(from: now)
        
        return timeString
    }
    
    func scrollDisplayViewDown() {
        displayLogTextTable.scrollToRow(at: IndexPath(row: displayLogTextTable.numberOfRows(inSection: 0) - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
    }

    func setManager(aManager : NORBluetoothManager?) {
        bluetoothManager = aManager
        
        if bluetoothManager != nil {
            commandTextField.placeholder = "Write command"
            commandTextField.text = ""
        } else {
            commandTextField.placeholder = "No UART service connected"
            commandTextField.text = ""
        }
    }

    //MARK: - UITextViewDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Only shows the keyboard when a UART peripheral is connected
        return bluetoothManager != nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.commandTextField.resignFirstResponder()
        bluetoothManager!.send(text: self.commandTextField.text!)
        self.commandTextField.text = ""
        return true
    }

    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logItems.count
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell") as! NORLogItemTableViewCell
        let item = logItems.object(at: (indexPath as NSIndexPath).row) as! NORLogItem
        cell.setItem(item: item)
        return cell
    }

    //MARK: - NORLogger Protocol
    func log(level aLevel: NORLOGLevel, message aMessage: String) {
        let item = NORLogItem()
        item.level = aLevel
        item.message = aMessage
        item.timestamp = getCurrentTime()
        logItems.add(item)
        
        DispatchQueue.main.async {
            //TODO: this is a bad fix to get things done, do not release!
            if self.displayLogTextTable != nil {
                self.displayLogTextTable!.reloadData()
                self.scrollDisplayViewDown()
            }
        }
    }
}
