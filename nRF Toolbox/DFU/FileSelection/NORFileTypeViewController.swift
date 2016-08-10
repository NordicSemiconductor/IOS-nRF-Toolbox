//
//  NORFileTypeViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class NORFileTypeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    var delegate            : NORFileTypeSelectionDelegate?
    var chosenFirmwareType  : DFUFirmwareType?
    var options             : NSArray?

    //MARK: - View Actions
    @IBAction func doneButtonTapped(sender: AnyObject) {
        handleDoneButtonTapEvent()
    }

    @IBAction func cancelButtonTapped(sender: AnyObject) {
        handleCancelButtonTapEvent()
    }
    
    
    //MARK: - UIViewControllerDelgeate
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        options = ["Softdevice", "Bootloader", "Application"]
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }

    override func viewWillDisappear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        super.viewWillDisappear(animated)
    }

    //MARK: - NORFileTypeViewController implementation
    func handleDoneButtonTapEvent() {
        delegate?.onFileTypeSelected(fileType: chosenFirmwareType!)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func handleCancelButtonTapEvent() {
        delegate?.onFileTypeNotSelected()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func pathToType(path aPath : NSIndexPath) -> DFUFirmwareType {
        switch aPath.row {
        case 0:
            return DFUFirmwareType.Softdevice
        case 1:
            return DFUFirmwareType.Bootloader
        default:
            return DFUFirmwareType.Application
        }
    }

    //MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (options?.count)!
    }

    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCellWithIdentifier("FileTypeCell", forIndexPath: indexPath)
        let cellType = options?.objectAtIndex(indexPath.row) as? String
        
        //Configure cell
        aCell.textLabel?.text = cellType
        if chosenFirmwareType == self.pathToType(path: indexPath) {
            aCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }else{
            aCell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return aCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        chosenFirmwareType = self.pathToType(path: indexPath)
        tableView.reloadData()
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
}
