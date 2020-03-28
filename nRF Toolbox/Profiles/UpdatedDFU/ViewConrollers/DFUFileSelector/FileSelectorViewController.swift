//
//  DFUFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary



class FileSelectorViewController<T, P: DFUPacket>: UIViewController, AlertPresenter, UITableViewDataSource, UITableViewDelegate {
    
    private let fileManager: DFUFileManager<P>
    
    private let documentPicker: DocumentPicker<T>
    
    private var documentFileManager = DocumentFileManager()
    private var fsItems: [FSNodeRepresentation] = []
    private dataSource = FSDataSource()
    
    private (set) var items: [P] = []
    @IBOutlet private var emptyView: UIView!
    @IBOutlet private var tableView: UITableView!
    
    init(documentPicker: DocumentPicker<T>, fileManager: DFUFileManager<P>) {
        self.documentPicker = documentPicker
        self.fileManager = fileManager
        super.init(nibName: "FileSelectorViewController", bundle: .main)
        navigationItem.title = "Select Package"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellClass(cell: NordicTextTableViewCell.self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: UIApplication.willEnterForegroundNotification, object: nil)
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
        
        if !items.isEmpty {
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
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicTextTableViewCell.self)
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

class DFUFileSelectorViewController: FileSelectorViewController<DFUFirmware, DFUDistributionPacket> {
    weak var router: DFURouterType?
    
    init(router: DFURouterType, documentPicker: DocumentPicker<DFUFirmware>) {
        self.router = router
        super.init(documentPicker: documentPicker, fileManager: DFUPacketManager())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: DFUFirmware) {
        router?.goToFirmwareInfo(firmware: document)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].firmware.flatMap { documentWasOpened(document: $0) }
    }
}
