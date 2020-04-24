//
//  DFUFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class FileSelectorViewController<T>: UIViewController, AlertPresenter, UITableViewDataSource, UITableViewDelegate {
    
    private let documentPicker: DocumentPicker<T>
    
    private var documentFileManager = DocumentFileManager()
    private (set) var dataSource = FSDataSource()
    var filterExtension: String? = nil  {
        didSet {
            dataSource.fileExtensionFilter = filterExtension
        }
    }
    
    @IBOutlet private var emptyView: UIView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var selectButton: NordicButton!
    
    init(documentPicker: DocumentPicker<T>) {
        self.documentPicker = documentPicker
        super.init(nibName: "FileSelectorViewController", bundle: .main)
        navigationItem.title = "Select Package"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellNib(cell: FileTableViewCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        selectButton.style = .mainAction
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadList))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadList()
    }
    
    @objc
    func reloadList() {
        do {
            let directory = try documentFileManager.buildDocumentDir()
            dataSource.updateItems(directory)
        } catch let error {
            displayErrorAlert(error: error)
            return
        }
        
        if !dataSource.items.isEmpty {
            view = tableView
            tableView.reloadData()
            tableView.backgroundColor = .groupTableViewBackground
        } else {
            view = emptyView
        }
    }
    
    func documentWasOpened(document: T) {
        
    }
    
    func fileWasSelected(file: File) {
        
    }
    
    @IBAction private func openDocumentPicker() {
        documentPicker.openDocumentPicker(presentOn: self) { [unowned self] (result) in
            switch result {
            case .success(let result):
                self.documentWasOpened(document: result)
            case .failure(let error):
                self.displayErrorAlert(error: error)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? dataSource.items.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Import Another"
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: FileTableViewCell.self)
        let item = dataSource.items[indexPath.row]
        cell.update(item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0
            ? UIDevice.current.userInterfaceIdiom == .pad
                ? 80
                : 66
            : 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            openDocumentPicker()
        } else if let file = dataSource.items[indexPath.row].node as? File, dataSource.items[indexPath.row].valid {
            fileWasSelected(file: file)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Documents Directory" : ""
    }
    
}

class DFUFileSelectorViewController: FileSelectorViewController<DFUFirmware> {
    weak var router: DFURouterType?
    
    init(router: DFURouterType, documentPicker: DocumentPicker<DFUFirmware>) {
        self.router = router
        super.init(documentPicker: documentPicker)
        filterExtension = "zip"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: DFUFirmware) {
        router?.goToFirmwareInfo(firmware: document)
    }
    
    override func fileWasSelected(file: File) {
        guard let firmware = DFUFirmware(urlToZipFile: file.url) else {
            displayErrorAlert(error: QuickError(message: "Can not create Firmware from selected file"))
            return
        }
        
        documentWasOpened(document: firmware)
    }
}
