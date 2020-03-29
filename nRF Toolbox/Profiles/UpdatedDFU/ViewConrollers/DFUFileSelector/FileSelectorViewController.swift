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
    private var fsItems: [FSNodeRepresentation] = []
    private (set) var dataSource = FSDataSource()
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        selectButton.style = .mainAction
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
        } else {
            view = emptyView
        }
    }
    
    func documentWasOpened(document: T) {
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: FileTableViewCell.self)
        let item = dataSource.items[indexPath.row]
        cell.update(item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 80 : 66
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Documents Directory"
    }
    
}

class DFUFileSelectorViewController: FileSelectorViewController<DFUFirmware> {
    weak var router: DFURouterType?
    
    init(router: DFURouterType, documentPicker: DocumentPicker<DFUFirmware>) {
        self.router = router
        super.init(documentPicker: documentPicker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: DFUFirmware) {
        router?.goToFirmwareInfo(firmware: document)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource.items[indexPath.row].node
        DFUFirmware(urlToZipFile: item.url).flatMap { self.documentWasOpened(document: $0) }
    }
}
