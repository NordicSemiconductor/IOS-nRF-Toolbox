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
    var selectedPath     : URL?
    var files            : NSArray?
    var appDirectoryPath : String?
    
    //MARK: - View Outlet
    @IBOutlet weak var tableView: UITableView!

    //MARK: - UIVIewControllerDelegate
    override func viewDidLoad() {
        super.viewDidLoad()

        self.appDirectoryPath = "firmwares" // self.appDirectoryPath = [self.fileSystem getAppDirectoryPath:@"firmwares"];
        
        let appPath = Bundle.main.resourceURL
        let firmwareDirectoryPath = appPath?.appendingPathComponent("firmwares")
        do{
            try self.files = FileManager.default.contentsOfDirectory(at: firmwareDirectoryPath!, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants) as NSArray?
        }catch{
            print("Error \(error)")
        }

        // The Navigation Item buttons may be initialized just once, here. They apply also to UserFilesVewController.
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.doneButtonTapped))
        self.tabBarController?.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(self.cancelButtonTapped))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = true
        if selectedPath == nil {
            self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated:true)
    }
    
    //MARK: - NORAppFilesViewController implementation
    func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        self.fileDelegate?.onFileSelected(withURL: self.selectedPath!)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }
    
    func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }

    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "AppFilesCell", for: indexPath)
        let fileURL = files?.object(at: (indexPath as NSIndexPath).row) as? URL
        let filePath = fileURL?.lastPathComponent

        //Cell config
        aCell.textLabel?.text = filePath
        
        if ((filePath?.contains(".hex")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if ((filePath?.contains(".bin")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if ((filePath?.contains(".zip")) != false) {
            aCell.imageView?.image = UIImage(named: "ic_archive")
        }else{
            aCell.imageView?.image = UIImage(named: "ic_file")
        }
        
        if filePath == selectedPath?.lastPathComponent {
            aCell.accessoryType = UITableViewCellAccessoryType.checkmark
        }else{
            aCell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        return aCell
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filePath = files?.object(at: (indexPath as NSIndexPath).row) as? URL
        selectedPath = filePath

        tableView.reloadData()

        self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = true
//        let userFilesViewController = self.tabBarController?.viewControllers?.last as? UserFilesViewController
//        userFilesViewController.selectedPath = selectedPath

    }
}
