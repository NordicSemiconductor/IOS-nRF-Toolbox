//
//  DFUFileDropView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUFileDropView: UIView {
    var handler: ((URL) -> ())!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addDropIntarection()
    }
    
    private func addDropIntarection() {
        if #available(iOS 11.0, *) {
            let dropInteraction = UIDropInteraction(delegate: self)
            addInteraction(dropInteraction)
        }
    }
}

@available(iOS 11.0, *)
extension DFUFileDropView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        item.itemProvider.loadFileRepresentation(forTypeIdentifier: "com.pkware.zip-archive") { url, error in
            if let error = error {
                Log(category: .ui, type: .error).log(message: "Can not drag file: \(error.localizedDescription)")
                return
            }

            guard let url = url else {
                Log(category: .ui, type: .error).log(message: "Drag&Drop: URL is empty")
                return
            }

            DispatchQueue.main.async {
                self.handler(url)
            }
        }
    }
}
