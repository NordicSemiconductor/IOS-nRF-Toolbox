//
//  UIImage+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init(rssi: Int32) {
        switch rssi {
        case let r where r < -90:
            self.init(named: "Signal_0")!
        case let r where r < -70:
            self.init(named: "Signal_1")!
        case let r where r < -50:
            self.init(named: "Signal_2")!
        default:
            self.init(named: "Signal_3")!
        }
    }
}
