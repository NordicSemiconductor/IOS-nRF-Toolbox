//
//  Identifier+GlucoseMonitorViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension Identifier: CaseIterable where Value == GlucoseMonitorViewController {
    static var allCases: [Identifier<GlucoseMonitorViewController>] {
        return [.all, .first, .last]
    }
    
    static let all: Identifier<GlucoseMonitorViewController> = "All"
    static let first: Identifier<GlucoseMonitorViewController> = "First"
    static let last: Identifier<GlucoseMonitorViewController> = "Last"
}
