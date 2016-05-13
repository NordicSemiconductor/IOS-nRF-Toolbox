//
//  NORUserFilesViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORUserFilesViewController: UIViewController, NORFilePreselectionDelegate, UITableViewDelegate,UITableViewDataSource {
    
    //MARK: - Class properties
    var fileDelegate : NORFileSelectionDelegate?
    var selectedPath : NSURL?
    var files        : [NSURL]?
    var documentsDirectoryPath : String?
    
    //MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    

    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
        files = [NSURL]()
        let fileManager = NSFileManager.defaultManager()
        let documentsURL = NSURL(string: documentsDirectoryPath!)

        do{
            try files = fileManager.contentsOfDirectoryAtURL(documentsURL!, includingPropertiesForKeys: [], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        }catch{
            print("Error \(error)")
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let buttonEnabled = selectedPath != nil
        self.tabBarController!.navigationItem.rightBarButtonItem!.enabled  = buttonEnabled
        ensureDirectoryNotEmpty()
    }
    
    //MARK: - NORUserFilesViewController
    func ensureDirectoryNotEmpty() {
        if files?.count == 0 {
            emptyView.hidden = false
        }
    }
    
    //MARK: - NORFilePreselectionDelegate
    func onFilePreselected(withURL aFileURL: NSURL) {
        selectedPath = aFileURL
        tableView.reloadData()
        self.tabBarController!.navigationItem.rightBarButtonItem!.enabled = true

        let appFilesVC = tabBarController?.viewControllers?.first as? NORAppFilesViewController
        appFilesVC?.selectedPath = selectedPath
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)! + 1 //Increment one for the tutorial on first row
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0{
            return 84
        }else{
            return 44
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            // Tutorial row
            return tableView.dequeueReusableCellWithIdentifier("UserFilesCellHelp", forIndexPath: indexPath)
        }
        
        self.ensureDirectoryNotEmpty()  //Always check if the table is emtpy

        // File row
        let aCell = tableView.dequeueReusableCellWithIdentifier("UserFilesCell", forIndexPath: indexPath)

        // Configure the cell...
        let filePath = (files?[indexPath.row-1])!
        let fileName = filePath.lastPathComponent
        print(fileName)

        aCell.textLabel?.text = fileName
        aCell.accessoryType = UITableViewCellAccessoryType.None
        
        //isDirHack
        var isDirectory : ObjCBool = false
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filePath.absoluteString, isDirectory: &isDirectory) {
            isDirectory = false
        }


        if isDirectory {
            aCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            if (fileName == "Inbox") {
                aCell.imageView?.image = UIImage(named:"ic_email")
            } else {
                aCell.imageView?.image = UIImage(named:"ic_folder")
            }
        }
        else if fileName!.lowercaseString.containsString(".hex") {
            aCell.imageView!.image = UIImage(named:"ic_file")
        }
        else if fileName!.lowercaseString.containsString("bin") {
            aCell.imageView!.image = UIImage(named:"ic_file")
        }
        else if fileName!.lowercaseString.containsString(".zip") {
            aCell.imageView!.image = UIImage(named:"ic_archive")
        }

        if selectedPath != nil {
            if filePath == selectedPath! {
                aCell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        }
        return aCell;
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            // Tutorial row
            self.performSegueWithIdentifier("OpenTutorial", sender: self)
        } else {
            // Normal row
            let filePath = files![indexPath.row - 1]

            //isDirHack
            var isDirectory : ObjCBool = true
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(filePath.absoluteString, isDirectory: &isDirectory) {
                isDirectory = false
            }

            if isDirectory {
                onFilePreselected(withURL: filePath)
            }else{
                // Folder clicked
                performSegueWithIdentifier("OpenFolder", sender: self)
            }
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.row > 0)
        {
            // Inbox folder can't be deleted
            let filePath = files?[indexPath.row-1]
            let fileName = filePath!.lastPathComponent
            
            if fileName?.lowercaseString == "inbox" {
                return UITableViewCellEditingStyle.Delete
            }
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let filePath = files?[indexPath.row-1]
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(filePath!)
                files?.removeAtIndex(indexPath.row-1)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                
                if filePath == selectedPath {
                    onFilePreselected(withURL: NSURL())
                }
            }catch{
                print("An error occured while deleting file\(error)")
            }
        }
    }
    
    //MARK: - Segue navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OpenFolder" {
            let selectionIndexPath = tableView.indexPathForSelectedRow
            let filePath = files![(selectionIndexPath?.row)! - 1]
            let fileName = filePath.lastPathComponent

            //isDirHack
            var isDirectory : ObjCBool = true
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(filePath.absoluteString, isDirectory: &isDirectory) {
                isDirectory = false
            }
            
            if isDirectory {
                let folderVC = segue.destinationViewController as? NORFolderFilesViewController
                folderVC?.directoryPath = filePath.absoluteString
                folderVC?.directoryName = fileName
                folderVC?.fileDelegate = fileDelegate!
                folderVC?.preselectionDelegate = self
                folderVC?.selectedPath = filePath
            }
        }
    }

}
