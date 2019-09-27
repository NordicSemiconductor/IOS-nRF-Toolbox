//
//  Identifier.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension Identifier where Value == Section {
    static let runningSpeedCadence: Identifier<Section> = "runningSpeedCadence"
    static let runningActivitySection: Identifier<Section> = "runningActivitySection"
}
