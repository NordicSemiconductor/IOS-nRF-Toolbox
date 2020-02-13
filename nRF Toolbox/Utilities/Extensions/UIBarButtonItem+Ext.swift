//
//  UIBarButtonItem+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    static func closeItem(target: Any?, action: Selector?) -> UIBarButtonItem {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
        } else {
            return UIBarButtonItem(title: "Close", style: .plain, target: target, action: action)
        }
    }
}
