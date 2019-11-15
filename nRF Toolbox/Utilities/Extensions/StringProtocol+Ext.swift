//
//  StringProtocol+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension StringProtocol {
    var hexa: [UInt8] {
        if count % 2 != 0 {
            return ("0" + self).hexa
        }
        var startIndex = self.startIndex
        return stride(from: 0, to: count, by: 2).compactMap { _ in
            let endIndex = index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}
