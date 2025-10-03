//
//  CGMSFeatureTets.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Testing
import Foundation
@testable import nRF_Toolbox

struct CGMSFeatureParsingTest {
    
    @Test("Valid input with E2E CRC supported and non-matching CRC")
    func testValidInputWithE2ECRCSupportedAndNonMatchingCRC() {
        let byteArray: [UInt8] = [0x01, 0x00, 0x10, 0x12, 0xFF, 0xEE] // "Hello" in ASCII
        let data = Data(byteArray)
        let feature = CGMSFeatureParser.parse(data: data)
        
        #expect(feature == nil, "CRC mismatch should return nil")
    }
    
    @Test("Valid input without E2E CRC and expected CRC as 0xFFFF")
    func validInputWithoutE2ECRC() {
        let byteArray: [UInt8] = [0x00, 0x00, 0x10, 0x12, 0xFF, 0xFF]
        let data = Data(byteArray)
        guard let result = CGMSFeatureParser.parse(data: data) else {
            Issue.record("Expected result to be non-nil")
            return
        }
        #expect(result.features.e2eCrcSupported == false)
    }
    
    @Test("Invalid input - byte array size not equal to 6")
    func invalidInputByteArraySize() {
        let byteArray: [UInt8] = [0x01, 0x00, 0x10] // Too short
        let data = Data(byteArray)
        let result = CGMSFeatureParser.parse(data: data)
        #expect(result == nil)
    }
    
    @Test("Type and sample location parsing")
    func typeAndSampleLocationParsing() {
        let byteArray: [UInt8] = [0x01, 0x00, 0x10, 0x21, 0xFF, 0xFF]
        let data = Data(byteArray)
        guard let result = CGMSFeatureParser.parse(data: data) else {
            Issue.record("Expected result to be non-nil")
            return
        }
        #expect(result.type == 1)
        #expect(result.sampleLocation == 2)
    }
}
