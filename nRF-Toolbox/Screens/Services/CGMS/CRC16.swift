//
//  CRC16.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

class CRC16 {
    
    static func mcrf4xx(data: Data, offset: Int, length: Int) -> UInt16 {
        return mcrf4xx(data: [UInt8](data), offset: offset, length: length)
    }
    
    static func mcrf4xx(data: [UInt8], offset: Int = 0, length: Int? = nil) -> UInt16 {
        let length = length ?? (data.count - offset)
        
        return crc(
            poly: 0x1021,
            initValue: 0xFFFF,
            data: data,
            offset: offset,
            length: length,
            refin: true,
            refout: true,
            xorout: 0x0000
        )
    }
    
    static func crc(
        poly: UInt16,
        initValue: UInt16,
        data: [UInt8],
        offset: Int,
        length: Int,
        refin: Bool,
        refout: Bool,
        xorout: UInt16
    ) -> UInt16 {
        var crc = UInt32(initValue)

        let end = min(offset + length, data.count)
        for i in offset..<end {
            let byte = data[i]

            for j in 0..<8 {
                let bitIndex = refin ? (7 - j) : j
                let bit = ((byte >> (7 - bitIndex)) & 1) != 0
                let c15 = ((crc >> 15) & 1) != 0

                crc <<= 1
                if c15 != bit {
                    crc ^= UInt32(poly)
                }
            }
        }

        if refout {
            crc = UInt32(reverseBits16(UInt32(crc))) ^ UInt32(xorout)
        } else {
            crc ^= UInt32(xorout)
        }

        return UInt16(crc & 0xFFFF)
    }
    
    static func reverseBits16(_ value: UInt32) -> UInt32 {
        var v = value
        v = (v & 0x5555) << 1 | (v >> 1) & 0x5555
        v = (v & 0x3333) << 2 | (v >> 2) & 0x3333
        v = (v & 0x0F0F) << 4 | (v >> 4) & 0x0F0F
        v = (v << 8) | (v >> 8)
        return v
    }
}
