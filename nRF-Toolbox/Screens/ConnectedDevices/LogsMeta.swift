//
//  LogsMeta.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 12/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

struct LogsMeta {
    let size: Int
    let maxSize: Int
    let percentageUsed: Int
    let percentageLeft: Int
    
    init() {
        self.init(size: 0.0)
    }

    init(size: Double) {
        self.size = Int(size)
        self.maxSize = 50
        self.percentageUsed = self.size * 100 / self.maxSize
        self.percentageLeft = 100 - self.percentageUsed
    }
}
