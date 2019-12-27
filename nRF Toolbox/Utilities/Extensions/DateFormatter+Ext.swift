//
//  DateFormatter+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension DateFormatter {
    static var longTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }
}
