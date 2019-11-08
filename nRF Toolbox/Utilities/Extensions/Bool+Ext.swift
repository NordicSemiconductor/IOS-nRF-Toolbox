//
// Created by Nick Kibysh on 28/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension Bool {
    mutating func toggle() {
        self = !self
    }

    func toggled() -> Bool { !self }
}