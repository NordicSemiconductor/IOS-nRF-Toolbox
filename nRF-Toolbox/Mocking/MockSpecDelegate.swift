//
//  MockSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 25/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import CoreBluetoothMock

protocol MockSpecDelegate : CBMPeripheralSpecDelegate {
    
    func getMainService() -> CBMServiceMock
}
