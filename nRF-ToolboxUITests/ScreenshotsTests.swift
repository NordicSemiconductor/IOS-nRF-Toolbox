//
//  Screenshots.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 28/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import XCTest

@MainActor
final class ScreenshotsTests: XCTestCase {
    
    var app: XCUIApplication!
    let sleepTime: UInt32 = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func setUp() {
        super.setUp()

        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testSnapshots() throws {
        let scannerButton = app/*@START_MENU_TOKEN@*/.staticTexts["Connect to Device"]/*[[".buttons[\"scannerButton\"].staticTexts",".buttons.staticTexts[\"Connect to Device\"]",".staticTexts[\"Connect to Device\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        scannerButton.tap()
        
        sleep(sleepTime)
        
        snapshot("ScannerScreen")
        
        sleep(sleepTime)
        app/*@START_MENU_TOKEN@*/.staticTexts["Cycling Speed and Cadence sensor"]/*[[".buttons[\"Cycling Speed and Cadence sensor\"].staticTexts",".buttons.staticTexts[\"Cycling Speed and Cadence sensor\"]",".staticTexts[\"Cycling Speed and Cadence sensor\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        sleep(sleepTime)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_0"]/*[[".buttons",".containing(.other, identifier: nil)",".containing(.staticText, identifier: \"Cycling Sensor\")",".containing(.image, identifier: \"cpu\")",".otherElements",".buttons[\"Cycling Sensor\"]",".buttons[\"device_item_0\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(sleepTime)
        snapshot("CSCSScreen")
        
        let backButton = app/*@START_MENU_TOKEN@*/.buttons["nRF Toolbox"]/*[[".navigationBars",".buttons",".buttons[\"nRF Toolbox\"]"],[[[-1,2],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        sleep(sleepTime)
        if backButton.exists { backButton.tap() }
        sleep(sleepTime)
        scannerButton.tap()
        
        sleep(sleepTime)
        app.buttons["Heart rate"].firstMatch.tap()
        sleep(sleepTime)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_1"]/*[[".buttons",".containing(.staticText, identifier: \"Heart Rate\")",".containing(.image, identifier: \"heart.fill\")",".containing(.staticText, identifier: \"Heart Rate Sensor\")",".otherElements",".buttons[\"Heart Rate Sensor\"]",".buttons[\"device_item_1\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(sleepTime)
        snapshot("HRSScreen")
        
        if backButton.exists { backButton.tap() }
        app/*@START_MENU_TOKEN@*/.buttons["scannerButton"]/*[[".buttons",".containing(.staticText, identifier: \"Connect to Device\")",".containing(.image, identifier: \"dot.radiowaves.right\")",".otherElements",".buttons[\"Connect to Device\"]",".buttons[\"scannerButton\"]"],[[[-1,5],[-1,4],[-1,3,2],[-1,0,1]],[[-1,2],[-1,1]],[[-1,5],[-1,4]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(sleepTime)
        app.buttons["Blood pressure"].firstMatch.tap()
        sleep(sleepTime)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_2"]/*[[".buttons",".containing(.staticText, identifier: \"Nordic UART Service\")",".containing(.image, identifier: \"character.cursor.ibeam\")",".containing(.staticText, identifier: \"UART\")",".otherElements",".buttons[\"UART\"]",".buttons[\"device_item_2\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(sleepTime)
        snapshot("BPSScreen")
        sleep(sleepTime)
        if backButton.exists {
            backButton.tap()
            snapshot("MainScreen")
        }
    }
}
