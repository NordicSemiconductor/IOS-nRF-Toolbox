//
//  Screenshots.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 28/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import XCTest

final class ScreenshotsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSnapshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.activate()
        
        snapshot("MainScreen")
        
        let element = app/*@START_MENU_TOKEN@*/.staticTexts["Connect to Device"]/*[[".buttons[\"scannerButton\"].staticTexts",".buttons.staticTexts[\"Connect to Device\"]",".staticTexts[\"Connect to Device\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        element.tap()
        
        sleep(5)
        app/*@START_MENU_TOKEN@*/.staticTexts["Cycling Speed and Cadence sensor"]/*[[".buttons[\"Cycling Speed and Cadence sensor\"].staticTexts",".buttons.staticTexts[\"Cycling Speed and Cadence sensor\"]",".staticTexts[\"Cycling Speed and Cadence sensor\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        sleep(5)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_0"]/*[[".buttons",".containing(.other, identifier: nil)",".containing(.staticText, identifier: \"Cycling Sensor\")",".containing(.image, identifier: \"cpu\")",".otherElements",".buttons[\"Cycling Sensor\"]",".buttons[\"device_item_0\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        sleep(5)
        app/*@START_MENU_TOKEN@*/.sliders["29"]/*[[".otherElements.sliders[\"29\"]",".sliders",".sliders[\"29\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.swipeLeft()
        
        sleep(5)
        snapshot("CSCSScreen")
        
        let element2 = app/*@START_MENU_TOKEN@*/.buttons["nRF Toolbox"]/*[[".navigationBars",".buttons",".buttons[\"nRF Toolbox\"]"],[[[-1,2],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        sleep(5)
        element2.tap()
        sleep(5)
        element.tap()
        
        sleep(5)
        app/*@START_MENU_TOKEN@*/.buttons["scanner_item_2"]/*[[".buttons.containing(.staticText, identifier: \"Heart rate\")",".otherElements",".buttons[\"Heart rate\"]",".buttons[\"scanner_item_2\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        sleep(5)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_1"]/*[[".buttons",".containing(.staticText, identifier: \"Heart Rate\")",".containing(.image, identifier: \"heart.fill\")",".containing(.staticText, identifier: \"Heart Rate Sensor\")",".otherElements",".buttons[\"Heart Rate Sensor\"]",".buttons[\"device_item_1\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(5)
        snapshot("HRSScreen")
        
        element2.tap()
        app/*@START_MENU_TOKEN@*/.buttons["scannerButton"]/*[[".buttons",".containing(.staticText, identifier: \"Connect to Device\")",".containing(.image, identifier: \"dot.radiowaves.right\")",".otherElements",".buttons[\"Connect to Device\"]",".buttons[\"scannerButton\"]"],[[[-1,5],[-1,4],[-1,3,2],[-1,0,1]],[[-1,2],[-1,1]],[[-1,5],[-1,4]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(5)
        app/*@START_MENU_TOKEN@*/.buttons["scanner_item_6"]/*[[".buttons.containing(.staticText, identifier: \"UART\")",".otherElements",".buttons[\"UART\"]",".buttons[\"scanner_item_6\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        sleep(5)
        app/*@START_MENU_TOKEN@*/.buttons["device_item_2"]/*[[".buttons",".containing(.staticText, identifier: \"Nordic UART Service\")",".containing(.image, identifier: \"character.cursor.ibeam\")",".containing(.staticText, identifier: \"UART\")",".otherElements",".buttons[\"UART\"]",".buttons[\"device_item_2\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        sleep(5)
        snapshot("HRSScreen")
        app.launch()
    }
}
