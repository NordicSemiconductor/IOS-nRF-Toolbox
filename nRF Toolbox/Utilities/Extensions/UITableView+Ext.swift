//
//  UITableView+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UITableView {
    func dequeueCell<T: UITableViewCell>(ofType type: T.Type) -> T {
        let cellId = String(describing: type)
        guard let cell = dequeueReusableCell(withIdentifier: cellId) as? T else {
            Log(category: .ui, type: .error).log(message: "Can not dequeue cell of type `\(cellId)` with cell ID '\(cellId)'")
            fatalError("Can not dequeue cell")
        }
        return cell 
    }
    
    func register<T: UITableViewCell>(cell type: T.Type) {
        let cellId = String(describing: type)
        let nib = UINib(nibName: cellId, bundle: .main)
        register(nib, forCellReuseIdentifier: cellId)
    }
}
