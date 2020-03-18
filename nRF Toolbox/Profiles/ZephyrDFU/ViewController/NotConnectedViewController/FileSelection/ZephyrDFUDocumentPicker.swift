//
//  ZephyrDFUDocumentPicker.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIDocumentPickerViewController

class ZephyrDFUDocumentPicker: DocumentPicker<Data> {
    init() {
        super.init(documentTypes: ["public.data"])
    }
    
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            let data = try Data(contentsOf: url)
            callback(.success(data))
        } catch let error {
            callback(.failure(error))
        }
    }
}
