/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
