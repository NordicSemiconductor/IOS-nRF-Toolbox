//
//  UARTMacroFileManagerTests.swift
//  nRF Toolbox Tests
//
//  Created by Nick Kibysh on 19/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import XCTest
@testable import nRF_Toolbox_Beta

class MockFileManager: FileManager {
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        return temporaryDirectory
    }
}

extension UARTMacro {
    static let mock = UARTMacro(name: "Mock", commands: UARTPreset.default.commands, preset: UARTPreset.default)
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
        XCTAssertNoThrow(try fileManager.save(macro, sholdUpdate: true), "Should rewrite file")
        XCTAssertNoThrow(try fileManager.remove(macro: macro), "Should remove macro")
    }
    
    func testContent() {
        XCTAssertNoThrow(try fileManager.save(macro), "Should save file into temp directory")
        XCTAssertNoThrow(try fileManager.macrosUrls())
        XCTAssertEqual(1, try fileManager.macrosUrls().count)
        XCTAssertEqual("Mock.json", try fileManager.macrosUrls().last?.lastPathComponent)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
