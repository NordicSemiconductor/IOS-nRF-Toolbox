//
//  DFUFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class FileSelectorViewController<T>: UIViewController, AlertPresenter {
    private let documentPicker: DocumentPicker<T>
    
    init(documentPicker: DocumentPicker<T>) {
        self.documentPicker = documentPicker
        super.init(nibName: "FileSelectorViewController", bundle: .main)
        navigationItem.title = "Select Package"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
}
