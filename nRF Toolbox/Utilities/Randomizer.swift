//
// Created by Nick Kibysh on 28/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

#if DEBUG
struct Randomizer: IteratorProtocol {
    let top, bottom: Double
    private var value: Double
    let delta: Double

    init(top: Double, bottom: Double, value: Double, delta: Double = 1.0) {
        self.top = top
        self.bottom = bottom
        self.value = value
        self.delta = delta
    }

    mutating func next() -> Double? {
        let rand = Double.random(in: -delta...delta)

        let inRange: (Double, Double, Double) -> Double = { minEdge, maxEdge, val in
            min(maxEdge, max(minEdge, val))
        }
        value = inRange(bottom, top, value + rand)
        return value
    }
}
#endif