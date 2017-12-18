//
//  NORDFUConstantsUtility.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORDFUConstantsUtility: NSObject {

    let dfuServiceUUIDString    = "00001530-1212-EFDE-1523-785FEABCD123"
    let ancSServiceUUIDString   = "7905F431-B5CE-4E99-A40F-4B1E122D00D0"

    static func getDFUHelpText() -> String {
        return "The Device Firmware Update (DFU) profile allows to upload a new application, Soft Device or bootloader onto the device over-the-air (OTA). It is compatible with nRF5x devices, from Nordic Semiconductor, that have the S110, S130 or S132 SoftDevice and the DFU bootloader enabled. \n\nDefault number of Packet Receipt Notification is 10 and can be changed in the Settings. For more information about the DFU check the documentation."
    }
    
    static func showAlert(message aMessage : String) {
        DispatchQueue.main.async { 
            let alert = UIAlertView(title: "DFU", message: aMessage, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
        
    }
    
    static func showBackgroundNotification(message aMessage : String) {
        let notification = UILocalNotification()
        notification.alertAction = "Show"
        notification.alertBody = aMessage
        notification.hasAction = false
        notification.fireDate = Date(timeIntervalSinceNow: 1)
        notification.timeZone = TimeZone.current
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    static func isApplicationStateInactiveOrBackgrounded () -> Bool {
        let appState = UIApplication.shared.applicationState
        return appState == UIApplicationState.inactive || appState == UIApplicationState.background
    }

}
