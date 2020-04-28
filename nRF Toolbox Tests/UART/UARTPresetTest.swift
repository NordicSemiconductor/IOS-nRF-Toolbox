//
//  UARTPresetTest.swift
//  nRF Toolbox Tests
//
//  Created by Nick Kibysh on 18/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import XCTest
@testable import nRF_Toolbox_Beta

func compare(_ command1: UARTMacroElement, _ command2: UARTMacroElement) -> Bool {
    switch (command1, command1) {
    case (let t1 as UARTMacroTimeInterval, let t2 as UARTMacroTimeInterval):
        return t1.milliseconds == t2.milliseconds
    case (is EmptyModel, is EmptyModel):
        return true
    case (let l as TextCommand, let r as TextCommand):
        return l == r
    case (let l as DataCommand, let r as DataCommand):
        return l == r
    default: return false
    }
}

extension UARTPreset: Equatable {
    public static func == (lhs: UARTPreset, rhs: UARTPreset) -> Bool {
        return lhs.name == rhs.name &&
            zip(lhs.commands, rhs.commands).reduce(true) {
                $0 && compare($1.0, $1.1)
            }
    }
}

class UARTPresetTests: XCTestCase {
    
    var defaultPreset: UARTPreset!
    var emptyPreset: UARTPreset!

    override func setUpWithError() throws {
        defaultPreset = UARTPreset.default
        emptyPreset = UARTPreset.empty
    }

    override func tearDownWithError() throws {
        
    }

    func testCoder() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        let encodedDefault = try encoder.encode(defaultPreset)
        let encodedEmpty = try encoder.encode(emptyPreset)
        
        let decodedDefault = try decoder.decode(UARTPreset.self, from: encodedDefault)
        let decodedEmpty = try decoder.decode(UARTPreset.self, from: encodedEmpty)
        
        XCTAssertEqual(defaultPreset, decodedDefault)
        XCTAssertEqual(decodedDefault.name, "Demo")
        XCTAssertEqual(emptyPreset, decodedEmpty)
    }

}
