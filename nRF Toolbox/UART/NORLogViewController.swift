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
    var logItems         : NSMutableArray?
    
    //MARK: - View Outlets
    @IBOutlet weak var displayLogTextTable : UITableView!
    @IBOutlet weak var commandTextField : UITextField!

    //MARK: - View Actions
    
    //MARK: - UIViewDelegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        logItems = NSMutableArray()
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
    
    //MARK: - NORLoggerViewController implementation
    func getCurrentTime() -> String {
        let now = NSDate()
        let outputFormatter = NSDateFormatter()
        outputFormatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = outputFormatter.stringFromDate(now)
        
        return timeString
    }
    
    func scrollDisplayViewDown() {
        displayLogTextTable.scrollToRowAtIndexPath(NSIndexPath(forRow: logItems!.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }

//    func setManager(aManager : NORBluetoothManager?) {
//        bluetoothManager = aManager
//        
//        if bluetoothManager != nil {
//            commandTextField.placeholder = "Write command"
//            commandTextField.text = ""
//        }else{
//            commandTextField.placeholder = "No UART service connected"
//            commandTextField.text = ""
//        }
//    }

    //MARK: - UITextViewDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        //Only shows the keyboard when a UART peripheral is connected
        return bluetoothManager != nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.commandTextField.resignFirstResponder()
        bluetoothManager!.send(text: self.commandTextField.text!)
        self.commandTextField.text = ""
        return true
    }

    //MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (logItems?.count)!
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("logCell") as! NORLogItemTableViewCell
        let item = logItems?.objectAtIndex(indexPath.row) as! NORLogItem
        cell.setItem(item: item)
        return cell
    }

    //MARK: - NORLogger Protocol
    func log(level aLevel: NORLOGLevel, message aMessage: String) {
        let item = NORLogItem()
        item.level = aLevel
        item.message = aMessage
        item.timestamp = getCurrentTime()
        logItems?.addObject(item)
        
        dispatch_async(dispatch_get_main_queue()) {
            //TODO: this is a bad fix to get things done, do not release!
            if self.displayLogTextTable != nil {
                self.displayLogTextTable!.reloadData()
                self.scrollDisplayViewDown()
            }
        }
    }
}
