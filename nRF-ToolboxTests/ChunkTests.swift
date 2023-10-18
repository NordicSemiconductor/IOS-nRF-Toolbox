//
//  ChunkTests.swift
//  nRF-ToolboxTests
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import XCTest
@testable import nRF_Toolbox

final class ChunkTests: XCTestCase {

    func testExample() {
        let arr1 = [1,2,3,4,5]
        let chuncked1 = arr1.chunk(2)
        XCTAssertEqual(chuncked1.count, 3)
        XCTAssertEqual(chuncked1[0][0], 1)
        XCTAssertEqual(chuncked1[0][1], 2)
        XCTAssertEqual(chuncked1[1][0], 3)
        XCTAssertEqual(chuncked1[1][1], 4)
    }
}
