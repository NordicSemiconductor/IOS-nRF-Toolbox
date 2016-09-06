//
//  NORFolderFilesViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORFolderFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //MARK: - Class Properties
    var files                   : NSMutableArray?
    var directoryPath           : String?
    var directoryName           : String?
    var fileDelegate            : NORFileSelectionDelegate?
    var preselectionDelegate    : NORFilePreselectionDelegate?
    var selectedPath            : NSURL?
    
    //MARK: - View Outlets
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var tableView: UITableView!

    //MARK: - View Actions
    @IBAction func doneButtonTapped(sender: AnyObject) {
        doneButtonTappedEventHandler()
    }

    //MARK: - UIViewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = directoryName!
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let enabled = (selectedPath != nil)
        self.navigationItem.rightBarButtonItem?.enabled = enabled
        self.ensureDirectoryNotEmpty()
    }

    //MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCellWithIdentifier("FolderFilesCell", forIndexPath:indexPath)
        let aFilePath = files?.objectAtIndex(indexPath.row) as? NSURL
        let fileName = aFilePath?.lastPathComponent
        
        //Configuring the cell
        aCell.textLabel?.text = fileName
        if fileName?.lowercaseString.containsString(".hex") != false {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if fileName?.lowercaseString.containsString(".bin") != false {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if fileName?.lowercaseString.containsString(".zip") != false {
            aCell.imageView?.image = UIImage(named: "ic_archive")
        }else{
            aCell.imageView?.image = UIImage(named: "ic_file")
        }
        
        if aFilePath == selectedPath {
            aCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }else{
            aCell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return aCell
    }

    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filePath = files?.objectAtIndex(indexPath.row) as? NSURL
        selectedPath = filePath
        tableView.reloadData()
        navigationItem.rightBarButtonItem!.enabled = true
        self.preselectionDelegate?.onFilePreselected(withURL: filePath!)
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        guard editingStyle == UITableViewCellEditingStyle.Delete else {
            return
        }

        let filePath = files?.objectAtIndex(indexPath.row) as? NSURL
        do{
            try NSFileManager.defaultManager().removeItemAtURL(filePath!)
        }catch{
            print("Error while deleting file: \(error)")
            return
        }

        files?.removeObjectAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    
        if filePath == selectedPath {
            selectedPath = nil
            self.preselectionDelegate?.onFilePreselected(withURL: NSURL())
            self.navigationItem.rightBarButtonItem?.enabled = false
        }

        self.ensureDirectoryNotEmpty()

    }
    //MARK: - NORFolderFilesViewController Implementation
    func ensureDirectoryNotEmpty() {
        if (files?.count)! == 0 {
            emptyView.hidden = false
        }
    }

    func doneButtonTappedEventHandler(){
        // Go back to DFUViewController
        dismissViewControllerAnimated(true) { 
            self.fileDelegate?.onFileSelected(withURL: self.selectedPath!)
        }
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
}
