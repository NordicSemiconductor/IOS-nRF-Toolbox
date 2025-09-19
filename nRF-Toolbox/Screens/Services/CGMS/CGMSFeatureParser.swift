//
//  CGMSFeatureParser.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//
import Foundation

class CGMSFeatureParser {
    
    static func parse(data: Data) -> CGMFeaturesEnvelope? {
        guard data.count == 6 else { return nil }
        
        var offset = 0
        guard let featuresValue = data.readUInt24(at: &offset) else { return nil }
        let typeAndSampleLocation = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
        offset += MemoryLayout<UInt8>.size
        let expectedCrc = data.littleEndianBytes(atOffset: offset, as: UInt16.self)
        offset += MemoryLayout<UInt16>.size
        
        let features = CGMFeatures(value: featuresValue)
        if features.e2eCrcSupported {
            let actualCrc = CRC16.mcrf4xx(data: data, offset: 0, length: 4)
            if actualCrc != expectedCrc {
                return nil
            }
        } else {
            if expectedCrc != 0xFFFF {
                return nil
            }
        }

        let type = typeAndSampleLocation & 0x0F
        let sampleLocation = typeAndSampleLocation >> 4

        return CGMFeaturesEnvelope(
            features: features,
            type: type,
            sampleLocation: sampleLocation,
            secured: features.e2eCrcSupported,
            crcValid: features.e2eCrcSupported
        )
    }
}

private extension Data {
    func readUInt24(at offset: inout Int) -> Int? {
        guard count >= offset + 3 else { return nil }
        let value = self[offset..<offset+3].reduce(0) { ($0 << 8) | Int($1) }
        offset += 3
        return value
    }
}
