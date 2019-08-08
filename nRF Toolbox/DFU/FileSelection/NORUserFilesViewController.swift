//
//  NORUserFilesViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORUserFilesViewController: UIViewController, NORFilePreselectionDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Class properties
    var fileDelegate : NORFileSelectionDelegate?
    var selectedPath : URL?
    var files        : [URL]!
    var documentsDirectoryPath : String?
    
    //MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!

    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        files = [URL]()
        let fileManager = FileManager.default
        let documentsURL = URL(string: documentsDirectoryPath!)

        do {
            try files = fileManager.contentsOfDirectory(at: documentsURL!, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
        } catch {
            print("Error \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let buttonEnabled = selectedPath != nil
        tabBarController!.navigationItem.rightBarButtonItem!.isEnabled = buttonEnabled
        ensureDirectoryNotEmpty()
    }
    
    //MARK: - NORUserFilesViewController
    func ensureDirectoryNotEmpty() {
        if files.count == 0 {
            emptyView.isHidden = false
        }
    }
    
    //MARK: - NORFilePreselectionDelegate
    func onFilePreselected(withURL aFileURL: URL) {
        selectedPath = aFileURL
        tableView.reloadData()
        tabBarController!.navigationItem.rightBarButtonItem!.isEnabled = true

        let appFilesVC = tabBarController?.viewControllers?.first as? NORAppFilesViewController
        appFilesVC?.selectedPath = selectedPath
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count + 1 //Increment one for the tutorial on first row
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 84
        } else {
            return 44
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // Tutorial row
            return tableView.dequeueReusableCell(withIdentifier: "UserFilesCellHelp", for: indexPath)
        }
        
        ensureDirectoryNotEmpty()  //Always check if the table is emtpy

        // File row
        let aCell = tableView.dequeueReusableCell(withIdentifier: "UserFilesCell", for: indexPath)

        // Configure the cell...
        let filePath = files[indexPath.row - 1]
        let fileName = filePath.lastPathComponent

        aCell.textLabel?.text = fileName
        aCell.accessoryType = .none
        
        var isDirectory : ObjCBool = false
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.relativePath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                aCell.accessoryType = .disclosureIndicator
                if fileName.lowercased() == "inbox" {
                    aCell.imageView?.image = UIImage(named: "ic_email")
                } else {
                    aCell.imageView?.image = UIImage(named: "ic_folder")
                }
            } else if fileName.lowercased().contains(".hex") {
                aCell.imageView!.image = UIImage(named: "ic_file")
            } else if fileName.lowercased().contains("bin") {
                aCell.imageView!.image = UIImage(named: "ic_file")
            } else if fileName.lowercased().contains(".zip") {
                aCell.imageView!.image = UIImage(named: "ic_archive")
            }
        } else {
            NORDFUConstantsUtility.showAlert(message: "File does not exist!", from: self)
        }

        if filePath == selectedPath {
            aCell.accessoryType = .checkmark
        }
        return aCell;
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Tutorial row
            performSegue(withIdentifier: "OpenTutorial", sender: indexPath)
        } else {
            // Normal row
            let filePath = files[indexPath.row - 1]

            var isDirectory : ObjCBool = false
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath.relativePath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    performSegue(withIdentifier: "OpenFolder", sender: indexPath)
                } else {
                    onFilePreselected(withURL: filePath)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row > 0 {
            // Inbox folder can't be deleted
            let filePath = files[indexPath.row - 1]
            let fileName = filePath.lastPathComponent
            
            if fileName.lowercased() == "inbox" {
                return .none
            } else {
                return .delete
            }
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let filePath = files[indexPath.row - 1]
            
            do {
                try FileManager.default.removeItem(at: filePath)
                files.remove(at: indexPath.row - 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                if filePath == selectedPath {
                    onFilePreselected(withURL: selectedPath!)
                }
            } catch {
                print("An error occured while deleting file\(error)")
            }
        }
    }
    
    //MARK: - Segue navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenFolder" {
            let selectionIndexPath = sender as! IndexPath
            let filePath = files[selectionIndexPath.row - 1]
            let fileName = filePath.lastPathComponent

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath.relativePath) {
                let folderVC = segue.destination as? NORFolderFilesViewController
                folderVC?.directoryPath = filePath.absoluteString
                folderVC?.directoryName = fileName
                folderVC?.fileDelegate = fileDelegate!
                folderVC?.preselectionDelegate = self
                folderVC?.selectedPath = filePath
            } else {
                NORDFUConstantsUtility.showAlert(message: "File does not exist!", from: self)
            }
        }
    }

}
