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
    var files                   : Array<URL>?
    var directoryPath           : String?
    var directoryName           : String?
    var fileDelegate            : NORFileSelectionDelegate?
    var preselectionDelegate    : NORFilePreselectionDelegate?
    var selectedPath            : URL?
    
    //MARK: - View Outlets
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var tableView: UITableView!

    //MARK: - View Actions
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        doneButtonTappedEventHandler()
    }

    //MARK: - UIViewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        if directoryName != nil {
            self.navigationItem.title = directoryName!
        }else{
            self.navigationItem.title = "Files"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let enabled = (selectedPath != nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = enabled
        do {
        try self.files = FileManager.default.contentsOfDirectory(at: selectedPath!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }catch{
            print(error)
        }
        self.ensureDirectoryNotEmpty()
    }

    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "FolderFilesCell", for:indexPath)
        let aFilePath = files?[indexPath.row]
        let fileName = aFilePath?.lastPathComponent
        
        //Configuring the cell
        aCell.textLabel?.text = fileName
        if fileName?.lowercased().contains(".hex") != false {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if fileName?.lowercased().contains(".bin") != false {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }else if fileName?.lowercased().contains(".zip") != false {
            aCell.imageView?.image = UIImage(named: "ic_archive")
        }else{
            aCell.imageView?.image = UIImage(named: "ic_file")
        }
        
        if aFilePath == selectedPath {
            aCell.accessoryType = UITableViewCellAccessoryType.checkmark
        }else{
            aCell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        return aCell
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filePath = files?[indexPath.row]
        selectedPath = filePath
        tableView.reloadData()
        navigationItem.rightBarButtonItem!.isEnabled = true
        self.preselectionDelegate?.onFilePreselected(withURL: filePath!)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        guard editingStyle == UITableViewCellEditingStyle.delete else {
            return
        }

        let filePath = files?[indexPath.row]
        do{
            try FileManager.default.removeItem(at: filePath!)
        }catch{
            print("Error while deleting file: \(error)")
            return
        }

        files?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
    
        if filePath == selectedPath {
            selectedPath = nil
            self.preselectionDelegate?.onFilePreselected(withURL: filePath!)
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        self.ensureDirectoryNotEmpty()

    }
    //MARK: - NORFolderFilesViewController Implementation
    func ensureDirectoryNotEmpty() {
        if (files?.count)! == 0 {
            emptyView.isHidden = false
        }
    }

    func doneButtonTappedEventHandler(){
        // Go back to DFUViewController
        dismiss(animated: true) { 
            self.fileDelegate?.onFileSelected(withURL: self.selectedPath!)
        }
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }
}
