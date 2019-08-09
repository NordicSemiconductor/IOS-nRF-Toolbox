//
//  HKHomeStore.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 06/03/2017.
//  Copyright © 2017 Nordic Semiconductor. All rights reserved.
//

import HomeKit

class HKHomeStore: NSObject, HMHomeManagerDelegate {
    static let sharedHomeStore = HKHomeStore()
    
    var home: HMHome?
    var homeManager = HMHomeManager()
}
