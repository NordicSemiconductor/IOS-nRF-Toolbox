//
//  nRF_ToolboxTests.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 19/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import XCTest
@testable import nRF_Toolbox

class NORCharacteristicReaderTests: XCTestCase {

    func testCharacteristicReaderAdvancesAfterRead() {
        let array : [UInt8] = [0x4e,0x4f,0x52,0x44,0x49,0x43,0x53,0x45,0x4d,0x49]
        var testData = UnsafeMutablePointer<UInt8>(mutating: array)
        var result : UInt8 = 10
        for aValue in array {
            result = NORCharacteristicReader.readUInt8Value(ptr: &testData)
            XCTAssertEqual(result, aValue, "Expected result is does not match output!")
        }
    }
}

