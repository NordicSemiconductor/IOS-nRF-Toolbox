//
//  MacrosElementCoderCoderTests.swift
//  nRF Toolbox Tests
//
//  Created by Nick Kibysh on 28/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import XCTest
@testable import UART

class MacrosElementCoderCoderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testComandDecode() {
        let command = TextCommand(text: "Text Command", image: .down, eol: .lf)
        let commandContainer = MacrosCommandContainer(command: command, repeatCount: 2, delay: 100)
        let element = MacrosElement.commandContainer(commandContainer)
        let commandContainerCoder = MacrosElementContainerCoder(container: element)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: commandContainerCoder, requiringSecureCoding: false)
            let newContainer = try NSKeyedUnarchiver.unarchivedObject(ofClass: MacrosElementContainerCoder.self, from: data)
            XCTAssertNotNil(newContainer, "Container should be decoded")
            
            switch newContainer!.container {
            case .commandContainer(let commandContainer):
                guard let textCommand = commandContainer.command as? TextCommand else {
                    XCTFail("Text command should be decoded")
                }
                
                XCTAssertEqual(textCommand.title, "text")
                XCTAssertEqual(textCommand.eol, EOL.cr)
                XCTAssertEqual(textCommand.icon.name, "")
                
                XCTAssertEqual(commandContainer.delay, 0)
                XCTAssertEqual(commandContainer.repeatCount, 0)
            default:
                XCTFail("Command container should be decoded")
            }
            
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
