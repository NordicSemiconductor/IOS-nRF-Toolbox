//
//  CRC16.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct CRC16 {
    
    static func MCRF4XX(data: Data, offset: Int, length: Int) -> UInt16 {
        return CRC16.mcrf4xx(data: data, offset: offset, length: length)
    }
    
    /// Compute CRC‑16 / MCRF4XX of a slice of data.
    /// - Parameters:
    ///   - data: Data buffer
    ///   - offset: start index in the data
    ///   - length: number of bytes to process from offset
    /// - Returns: 16‑bit CRC value as UInt16
    static func mcrf4xx(data: Data, offset: Int, length: Int) -> UInt16 {
        let polynomial: UInt16 = 0x1021
        var crc: UInt16 = 0xFFFF
        let end = offset + length
        guard offset >= 0, end <= data.count else {
            // Out of bounds, return something (you might also throw or assert)
            return 0
        }
        
        for i in offset..<end {
            crc ^= UInt16(data[i]) << 8
            for _ in 0..<8 {
                if (crc & 0x8000) != 0 {
                    crc = (crc << 1) ^ polynomial
                } else {
                    crc = crc << 1
                }
            }
        }
        return crc
    }
}
