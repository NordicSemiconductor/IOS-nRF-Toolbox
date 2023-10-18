//
//  Array+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension RandomAccessCollection {
    func chunk(_ n: UInt) -> [[Element]] {
        return self.reduce(into: [[Element]]()) { partialResult, element in
            assert(n != 0)
            
            guard let last = partialResult.last else {
                partialResult.append([element])
                return
            }
            
            if last.count < n {
                var l = partialResult.popLast()
                l?.append(element)
                partialResult.append(l!)
            } else {
                partialResult.append([element])
            }
        }
    }
}
