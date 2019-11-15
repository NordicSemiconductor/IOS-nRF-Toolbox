//
//  SelectFileView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 13/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class SelectFileView: InfoActionView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        enableDroping()
    }
    
    private func enableDroping() {
        if #available(iOS 11.0, *) {
            let interaction = UIDropInteraction(delegate: self)
            self.addInteraction(interaction)
        }
    }
    
}

@available(iOS 11.0, *)
extension SelectFileView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
    }
}
