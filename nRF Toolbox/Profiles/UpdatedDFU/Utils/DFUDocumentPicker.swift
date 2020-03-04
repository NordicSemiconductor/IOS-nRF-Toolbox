//
//  DFUDocumentPicker.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class DFUDocumentPicker: NSObject, UIDocumentPickerDelegate {
    typealias Callback = (Result<DFUFirmware, Error>) -> ()
    private var callback: Callback!
    
    func openDocumentPicker(presentOn controller: UIViewController, callback: @escaping Callback) {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["com.pkware.zip-archive"], in: .import)
        documentPickerVC.delegate = self
        controller.present(documentPickerVC, animated: true)
        self.callback = callback
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let firmware = DFUFirmware(urlToZipFile: url) else {
            callback(.failure(QuickError(message: "Can not create Firmware")))
            return
        }
        
        callback(.success(firmware))
    }
}
