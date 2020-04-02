//
//  UICollectionView+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UICollectionView {
    func dequeueCell<T: UICollectionViewCell>(ofType type: T.Type, for indexPath: IndexPath) -> T {
        let cellId = String(describing: type)
        guard let cell = dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? T else {
            SystemLog(category: .ui, type: .error).log(message: "Can not dequeue cell of type `\(cellId)` with cell ID '\(cellId)'")
            fatalError("Can not dequeue cell")
        }
        return cell
    }
    
    func register<T>(type: T.Type) where T: UICollectionViewCell {
        let cellId = String(describing: type)
        let nib = UINib(nibName: cellId, bundle: .main)
        register(nib, forCellWithReuseIdentifier: cellId)
    }
}
