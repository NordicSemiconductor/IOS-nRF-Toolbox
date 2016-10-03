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
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        handleDoneButtonTapEvent()
    }

    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        handleCancelButtonTapEvent()
    }
    
    
    //MARK: - UIViewControllerDelgeate
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        options = ["Softdevice", "Bootloader", "Application"]
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        super.viewWillDisappear(animated)
    }

    //MARK: - NORFileTypeViewController implementation
    func handleDoneButtonTapEvent() {
        delegate?.onFileTypeSelected(fileType: chosenFirmwareType!)
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleCancelButtonTapEvent() {
        delegate?.onFileTypeNotSelected()
        self.dismiss(animated: true, completion: nil)
    }

    func pathToType(path aPath : NSIndexPath) -> DFUFirmwareType {
        switch aPath.row {
        case 0:
            return DFUFirmwareType.softdevice
        case 1:
            return DFUFirmwareType.bootloader
        default:
            return DFUFirmwareType.application
        }
    }

    //MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (options?.count)!
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "FileTypeCell", for: indexPath)
        let cellType = options?.object(at: (indexPath as NSIndexPath).row) as? String
        
        //Configure cell
        aCell.textLabel?.text = cellType
        if chosenFirmwareType == self.pathToType(path: indexPath as NSIndexPath) {
            aCell.accessoryType = UITableViewCellAccessoryType.checkmark
        }else{
            aCell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        return aCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenFirmwareType = self.pathToType(path: indexPath as NSIndexPath)
        tableView.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
