//
//  HKScannerDelegate.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 07/03/2017.
//  Copyright © 2017 Nordic Semiconductor. All rights reserved.
//

import UIKit
import HomeKit

protocol HKScannerDelegate {
    func browser(aBrowser: HMAccessoryBrowser, didSelectAccessory anAccessory: HMAccessory)
}
