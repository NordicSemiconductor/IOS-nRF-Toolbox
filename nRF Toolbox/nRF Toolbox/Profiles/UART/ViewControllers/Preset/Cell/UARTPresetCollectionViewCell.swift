//
//  UARTPresetCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 15.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTPresetDelegate {
    func save(preset: UARTPreset)
    func saveAs(preset: UARTPreset)
    func toggleFavorite(preset: UARTPreset)
    func export(preset: UARTPreset)
    func removeFromQuickAccess(preset: UARTPreset)
    func rename(preset: UARTPreset)
}

class UARTPresetCollectionViewCell: UICollectionViewCell {
    
    weak var viewController: UIViewController?
    var presetDelegate: UARTPresetDelegate?
    
    var preset: UARTPreset! {
        didSet {
            presetCollectionView.preset = preset
            presetCollectionView.reloadData()
            presetName.text = preset.name
            
            moreButton.isHidden = preset.isEmpty
        }
    }
    
    @IBOutlet var presetCollectionView: UARTPresetCollectionView!
    @IBOutlet var presetName: UILabel!
    @IBOutlet var moreButton: UIButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction private func moreBtnPressed() {
        
        guard let vc = viewController else { return }
        
        let removeAction = UIAlertAction(title: "Remove from quick access", style: .destructive) { (_) in
            self.presetDelegate?.removeFromQuickAccess(preset: self.preset)
        }
        
        let removeFromFavorite = UIAlertAction(title: "Remove from favorite", style: .destructive) { (_) in
            self.presetDelegate?.toggleFavorite(preset: self.preset)
        }
        
        let addToFavorite = UIAlertAction(title: "Add to favorite", style: .default) { (_) in
            self.presetDelegate?.toggleFavorite(preset: self.preset)
        }
        
        let export = UIAlertAction(title: "Export", style: .default) { (_) in
            self.presetDelegate?.export(preset: self.preset)
        }
        
        let saveAs = UIAlertAction(title: "Save As", style: .default) { (_) in
            self.presetDelegate?.saveAs(preset: self.preset)
        }
        
        let rename = UIAlertAction(title: "Rename", style: .default) { (_) in
            self.presetDelegate?.rename(preset: self.preset)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        let alertController = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        
        if preset.isFavorite {
            alertController.addAction(removeFromFavorite)
        } else {
            alertController.addAction(addToFavorite)
        }
        
        alertController.addAction(saveAs)
        
        alertController.addAction(export)
        alertController.addAction(removeAction)
        alertController.addAction(cancel)
        alertController.addAction(rename)
        
        vc.present(alertController, animated: true) { }
        
    }
    
}
