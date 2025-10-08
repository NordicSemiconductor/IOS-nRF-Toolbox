//
//  CGMSMeasurementParser.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 25/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

class CGMSMeasurementParser {
    
    private static let log = NordicLog(category: "CGMSMeasurementParser", subsystem: "com.nordicsemi.nrf-toolbox")
    
    static func parse(data: Data, sessionStartTime: Date) -> [CGMSMeasurement] {
        var result = [CGMSMeasurement]()
        
        var offset = 0
        var subdata = data
        
        let size = MemoryLayout<UInt16>.size
        
        while (offset < data.count) {
            subdata = data.subdata(in: offset..<data.count)
            guard let parsedValue = try? CGMSMeasurement(data: subdata, sessionStartTime: sessionStartTime) else {
                log.error("Unable to parse Measurement Data \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                return result
            }
            offset += parsedValue.measuredSize
            result.append(parsedValue)
        }
        
        return result
    }
}
