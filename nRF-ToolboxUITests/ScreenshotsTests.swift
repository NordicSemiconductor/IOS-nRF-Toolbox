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
        let element = app/*@START_MENU_TOKEN@*/.staticTexts["Connect to Device"]/*[[".buttons[\"scannerButton\"].staticTexts",".buttons.staticTexts[\"Connect to Device\"]",".staticTexts[\"Connect to Device\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        element.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Cycling Speed and Cadence sensor"]/*[[".buttons[\"Cycling Speed and Cadence sensor\"].staticTexts",".buttons.staticTexts[\"Cycling Speed and Cadence sensor\"]",".staticTexts[\"Cycling Speed and Cadence sensor\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["device_item_0"]/*[[".buttons",".containing(.other, identifier: nil)",".containing(.staticText, identifier: \"Cycling Sensor\")",".containing(.image, identifier: \"cpu\")",".otherElements",".buttons[\"Cycling Sensor\"]",".buttons[\"device_item_0\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.sliders["29"]/*[[".otherElements.sliders[\"29\"]",".sliders",".sliders[\"29\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.swipeLeft()
        
        let element2 = app/*@START_MENU_TOKEN@*/.buttons["nRF Toolbox"]/*[[".navigationBars",".buttons",".buttons[\"nRF Toolbox\"]"],[[[-1,2],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        element2.tap()
        element.tap()
        app/*@START_MENU_TOKEN@*/.buttons["scanner_item_2"]/*[[".buttons.containing(.staticText, identifier: \"Heart rate\")",".otherElements",".buttons[\"Heart rate\"]",".buttons[\"scanner_item_2\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["device_item_1"]/*[[".buttons",".containing(.staticText, identifier: \"Heart Rate\")",".containing(.image, identifier: \"heart.fill\")",".containing(.staticText, identifier: \"Heart Rate Sensor\")",".otherElements",".buttons[\"Heart Rate Sensor\"]",".buttons[\"device_item_1\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        element2.tap()
        app/*@START_MENU_TOKEN@*/.buttons["scannerButton"]/*[[".buttons",".containing(.staticText, identifier: \"Connect to Device\")",".containing(.image, identifier: \"dot.radiowaves.right\")",".otherElements",".buttons[\"Connect to Device\"]",".buttons[\"scannerButton\"]"],[[[-1,5],[-1,4],[-1,3,2],[-1,0,1]],[[-1,2],[-1,1]],[[-1,5],[-1,4]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["scanner_item_6"]/*[[".buttons.containing(.staticText, identifier: \"UART\")",".otherElements",".buttons[\"UART\"]",".buttons[\"scanner_item_6\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["device_item_2"]/*[[".buttons",".containing(.staticText, identifier: \"Nordic UART Service\")",".containing(.image, identifier: \"character.cursor.ibeam\")",".containing(.staticText, identifier: \"UART\")",".otherElements",".buttons[\"UART\"]",".buttons[\"device_item_2\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["All Messages (0)"]/*[[".buttons",".containing(.image, identifier: \"chevron.forward\")",".containing(.staticText, identifier: \"All Messages (0)\")",".otherElements.buttons[\"All Messages (0)\"]",".buttons[\"All Messages (0)\"]"],[[[-1,4],[-1,3],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Presets"]/*[[".buttons[\"Presets\"].staticTexts",".buttons.staticTexts[\"Presets\"]",".staticTexts[\"Presets\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["play"]/*[[".otherElements.buttons[\"play\"]",".buttons[\"play\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        element2.doubleTap()
        app.launch()
        
//        snapshot("MainScreen")
//        
//        app.buttons["scannerButton"].tap()
//        
//        sleep(5)
//        
//        snapshot("ScannerScreen")
//        
//        app.buttons["scanner_item_0"].tap()
//        
//        sleep(5)
//        
//        app.buttons["scanner_item_0"].tap()
//        
//        sleep(5)
//        
//        app.buttons["device_item_0"].tap()
//        
//        snapshot("Device0Screen")
//        
//        sleep(5)
//        
//        app.buttons["disconnect_button"].tap()
//        
//        sleep(5)
//        
//        app.buttons["scanner_item_1"].tap()
//        
//        sleep(5)
//        
//        app.buttons["device_item_1"].tap()
//        
//        snapshot("Device1Screen")
//        
//        sleep(5)
//        
//        app.buttons["disconnect_button"].tap()
//        
//        sleep(5)
//        
//        app.buttons["scanner_item_2"].tap()
//        
//        sleep(5)
//        
//        app.buttons["device_item_2"].tap()
//        
//        snapshot("Device2Screen")
//        
//        sleep(5)
//        
//        app.buttons["disconnect_button"].tap()
    }
}
