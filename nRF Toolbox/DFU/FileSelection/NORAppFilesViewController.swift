//
//  NORAppFilesViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORAppFilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - Class Properties
    var fileDelegate     : NORFileSelectionDelegate?
    var selectedPath     : NSURL?
    var files            : NSArray?
    var appDirectoryPath : String?
    
    //MARK: - View Outlet
    @IBOutlet weak var tableView: UITableView!

    //MARK: - UIVIewControllerDelegate
    override func viewDidLoad() {
        super.viewDidLoad()

        self.appDirectoryPath = "firmwares" // self.appDirectoryPath = [self.fileSystem getAppDirectoryPath:@"firmwares"];
        
        let appPath = NSBundle.mainBundle().resourceURL
        let firmwareDirectoryPath = appPath?.URLByAppendingPathComponent("firmwares")
        do{
            try self.files = NSFileManager.defaultManager().contentsOfDirectoryAtURL(firmwareDirectoryPath!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
        }catch{
            print("Error \(error)")
        }

        // The Navigation Item buttons may be initialized just once, here. They apply also to UserFilesVewController.
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(self.doneButtonTapped))
        self.tabBarController?.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(self.cancelButtonTapped))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.navigationItem.rightBarButtonItem?.enabled = true
        if selectedPath == nil {
            self.tabBarController?.navigationItem.rightBarButtonItem?.enabled = false
        }
        tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated:true)
    }
    
    //MARK: - NORAppFilesViewController implementation
    func doneButtonTapped() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.fileDelegate?.onFileSelected(withURL: self.selectedPath!)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func cancelButtonTapped() {
        self.dismissViewControllerAnimated(true, completion: nil)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }

    //MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCellWithIdentifier("AppFilesCell", forIndexPath: indexPath)
        let fileURL = files?.objectAtIndex(indexPath.row) as? NSURL
        let filePath = fileURL?.lastPathComponent

        //Cell config
        aCell.textLabel?.text = filePath
        
        if ((filePath?.containsString(".hex")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if ((filePath?.containsString(".bin")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if ((filePath?.containsString(".zip")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_archive")
        }else{
            aCell.imageView?.image = UIImage(named: "ic_file")
        }
        
        if filePath == selectedPath?.lastPathComponent {
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

        self.tabBarController?.navigationItem.rightBarButtonItem?.enabled = true
//        let userFilesViewController = self.tabBarController?.viewControllers?.last as? UserFilesViewController
//        userFilesViewController.selectedPath = selectedPath

    }
}
