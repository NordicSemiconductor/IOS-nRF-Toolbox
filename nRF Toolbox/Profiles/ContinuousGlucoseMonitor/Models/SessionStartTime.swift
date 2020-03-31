//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct SessionStartTime {
    let date: Date

    init(data: Data) {
        self.date = data.readDate(from: 0)
        SystemLog(category: .util, type: .debug).log(message: "Session Date: \(self.date)")
    }

    init(date: Date) {
        self.date = date
    }
}