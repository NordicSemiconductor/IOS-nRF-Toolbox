/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit
import NordicDFU
import UniformTypeIdentifiers

class DocumentPicker<T>: NSObject, UIDocumentPickerDelegate {
    typealias Callback = (Result<T, Error>) -> ()
    private (set) var callback: Callback!
    let types: [String]
    
    init(documentTypes: [String]) {
        types = documentTypes
        super.init()
    }
    
    func openDocumentPicker(presentOn controller: UIViewController, callback: @escaping Callback) {
        let documentPickerVC: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            documentPickerVC = UIDocumentPickerViewController(forOpeningContentTypes: self.types.map { UTTypeReference(importedAs: $0) as UTType })
        } else {
            documentPickerVC = UIDocumentPickerViewController(documentTypes: types, in: .import)
        }
        documentPickerVC.delegate = self
        controller.present(documentPickerVC, animated: true)
        self.callback = callback
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    }
}

class DFUDocumentPicker: DocumentPicker<DFUFirmware> {
    init() {
        super.init(documentTypes: ["com.pkware.zip-archive"])
    }
    
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let firmware = DFUFirmware(urlToZipFile: url) else {
            callback(.failure(QuickError(message: "Can not create Firmware")))
            return
        }
        
        callback(.success(firmware))
    }
}
