//
//  UARTPresetCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 15.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTPresetCollectionViewCell: UICollectionViewCell {
    
    weak var viewController: UIViewController?
    
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
            
        }
        
        let removeFromFavorite = UIAlertAction(title: "Remove from favorite", style: .destructive) { (_) in
            
        }
        
        let addToFavorite = UIAlertAction(title: "Add to favorite", style: .default) { (_) in
            
        }
        
        let export = UIAlertAction(title: "Export", style: .default) { (_) in
            
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        
        let alertController = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(addToFavorite)
        alertController.addAction(export)
        alertController.addAction(removeAction)
        alertController.addAction(cancel)
        
        vc.present(alertController, animated: true) {
            
        }
        
    }
    
}
