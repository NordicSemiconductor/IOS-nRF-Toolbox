//
//  XibInstantiable.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol XibInstantiable: class {
    static func instance() -> Self
}

extension XibInstantiable where Self: UIView {
    static func instance() -> Self {
        let name = String(describing: self)
        guard let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? Self else {
            let errorMessage = "Cannot load nib named \(name)"
            Log(category: .ui, type: .fault).log(message: errorMessage)
            fatalError(errorMessage)
        }
        
        return view
    }
}
