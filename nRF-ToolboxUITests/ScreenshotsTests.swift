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
    func takeSnapshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        snapshot("MainScreen")
        
        app.buttons["scannerButton"].tap()
        
        sleep(5)
        
        snapshot("ScannerScreen")
        
        app.buttons["scanner_item_0"].tap()
        
        sleep(5)
        
        app.buttons["scanner_item_0"].tap()
        
        sleep(5)
        
        app.buttons["device_item_0"].tap()
        
        snapshot("Device0Screen")
        
        sleep(5)
        
        app.buttons["disconnect_button"].tap()
        
        sleep(5)
        
        app.buttons["scanner_item_1"].tap()
        
        sleep(5)
        
        app.buttons["device_item_1"].tap()
        
        snapshot("Device1Screen")
        
        sleep(5)
        
        app.buttons["disconnect_button"].tap()
        
        sleep(5)
        
        app.buttons["scanner_item_2"].tap()
        
        sleep(5)
        
        app.buttons["device_item_2"].tap()
        
        snapshot("Device2Screen")
        
        sleep(5)
        
        app.buttons["disconnect_button"].tap()
    }
}
