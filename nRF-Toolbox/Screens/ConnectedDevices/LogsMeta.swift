//
//  LogsMeta.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 12/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

struct LogsMeta {
    let count: Int
    let maxCount: Int
    let percentageUsed: Int
    let percentageLeft: Int
    
    init() {
        self.init(size: 0.0)
    }

    init(size: Double) {
        self.count = Int(size)
        self.maxCount = 100_000
        self.percentageUsed = self.count * 100 / self.maxCount
        self.percentageLeft = 100 - self.percentageUsed
    }
}
