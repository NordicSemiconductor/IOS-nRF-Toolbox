//
//  CGRect+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension CGRect {
    var minSide: CGFloat {
        min(size.width, size.height)
    }
    
    var maxSide: CGFloat {
        max(size.width, size.height)
    }
}
