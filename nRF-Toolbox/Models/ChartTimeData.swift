//
//  ChartTimeData.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 31/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct ChartTimeData<T> {
    let value: T
    let date: Date
    
    init(value: T, date: Date = Date()) {
        self.value = value
        self.date = date
    }
}
