//
//  DFUFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class DFUFileSelector: UIViewController, AlertPresenter {
    
    weak var router: DFURouterType?
    private let documentPicker = DFUDocumentPicker()
    
    init(router: DFURouterType? = nil) {
        self.router = router
        super.init(nibName: "DFUFileSelector", bundle: .main)
        navigationItem.title = "Select Package"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func openDocumentPicker() {
        documentPicker.openDocumentPicker(presentOn: self) { [unowned self] (result) in
            switch result {
            case .success(let firmware):
                self.router?.goToFirmwareInfo(firmware: firmware)
            case .failure(let error):
                self.displayErrorAlert(error: error)
            }
        }
    }
}
