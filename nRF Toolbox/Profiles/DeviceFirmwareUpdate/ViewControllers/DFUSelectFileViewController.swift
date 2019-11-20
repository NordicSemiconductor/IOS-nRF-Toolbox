//
//  DFUSelectFileViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUSelectFileViewController: UIViewController {

    @IBOutlet var dropView: DFUFileDropView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Select File"
        dropView.handler = { [unowned self] url in
            self.openFile(url)
        }
    }
    
    @IBAction func select() {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["com.pkware.zip-archive"], in: .open)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
    }
    
    private func openFile(_ url: URL) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "DFUPacketInfoViewController") as? DFUPacketInfoViewController else {
            return
        }
        
        vc.url = url
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension DFUSelectFileViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        openFile(url)
    }
}
