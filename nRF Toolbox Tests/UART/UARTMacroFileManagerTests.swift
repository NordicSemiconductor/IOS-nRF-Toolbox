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

class MockFileManager: FileManager {
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        return temporaryDirectory
    }
}

extension UARTMacro: Equatable {
    static let mock = UARTMacro(name: "Mock", commands: UARTPreset.default.commands, preset: UARTPreset.default)
    
    public static func == (lhs: UARTMacro, rhs: UARTMacro) -> Bool {
        lhs.preset == rhs.preset
            && lhs.name == rhs.name
            && zip(lhs.commands, rhs.commands).reduce(true) {
                $0 && compare($1.0, $1.1)
            }
    }
}

class UARTMacroFileManagerTests: XCTestCase {

    var fileManager: UARTMacroFileManager!
    var macro: UARTMacro!
    
    override func setUpWithError() throws {
        fileManager = UARTMacroFileManager(fileManager: MockFileManager())
        macro = UARTMacro.mock
    }

    override func tearDownWithError() throws {
        try? fileManager.remove(macro: macro)
    }

    func testSavingAndRemoving() throws {
        XCTAssertThrowsError(try fileManager.remove(macro: macro), "Should throww error as macros does not exist")
        XCTAssertNoThrow(try fileManager.save(macro), "Should save file into temp directory")
        XCTAssertThrowsError(try fileManager.save(macro), "Should throw exeption as file already exists")
        XCTAssertNoThrow(try fileManager.save(macro, shodUpdate: true), "Should rewrite file")
        XCTAssertNoThrow(try fileManager.remove(macro: macro), "Should remove macro")
    }
    
    func testContent() {
        XCTAssertNoThrow(try fileManager.save(macro), "Should save file into temp directory")
        XCTAssertNoThrow(try fileManager.macrosList())
        XCTAssertEqual(1, try fileManager.macrosList().count)
        XCTAssertEqual("Mock", try fileManager.macrosList().last)
    }
    
    func testMacrosLoading() throws {
        XCTAssertNoThrow(try fileManager.save(macro), "Should save file into temp directory")
        let loadedMacros = try fileManager.macros(for: macro.name)
        XCTAssertEqual(loadedMacros, macro)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
