//
//  NORAppUtilities.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum NORServiceIds : UInt8 {
    case UART       = 0
    case RSC        = 1
    case Proximity  = 2
    case HTM        = 3
    case HRM        = 4
    case CSC        = 5
    case BPM        = 6
    case BGM        = 7
    case CGM        = 8
}

class NORAppUtilities: NSObject {
    
    static let uartHelpText = "This profile allows you to connect to a device that support Nordic's UART service. The service allows you to send and receive short messages of 20 bytes in total.\n\nThe main screen contains 9 programmable buttons. Use the Edit button to edit a command or an icon assigned to each button. Unused buttons may be hidden.\n\nTap the Show Log button to see the conversation or to send a custom message."
    
    static let rscHelpText  = "The RSC (Running Speed and Cadence) profile allows you to connect to your activity sensor. It reads speed and cadence values from the sensor and calculates trip distance if stride length is supported. Strides count is calculated by using cadence and the time."
    
    static let proximityHelpText = "The PROXIMITY profile allows you to connect to your Proximity sensor. Later on you can find your valuables attached with Proximity tag by pressing the FindMe button on the screen or your phone by pressing relevant button on your tag. A notification will appear on your phone screen when you go away from your connected tag."
    

    static let htmHelpText = "The HTM (Health Thermometer Monitor) profile allows you to connect to your Health Thermometer sensor. It displays the temperature value in Celsius or Fahrenheit degrees."

    static let hrmHelpText = "The HRM (Heart Rate Monitor) profile allows you to connect and read data from your Heart Rate sensor (eg. a belt). It shows the current heart rate, location of the sensor and displays the historical data on a graph."

    static let cscHelpText = "The CSC (Cycling Speed and Cadence) profile allows you to connect to your bike activity sensor. It reads wheel and crank data if the sensor supports it, and calculates speed, cadence, total and trip distance and gear ratio. The default wheel size is set to 29 inches but you can set up wheel size in the Settings."
    
    static let bpmHelpText = "The BPM (Blood Pressure Monitor) profile allows you to connect to your Blood Pressure device. It supports the cuff pressure notifications and displays systolic, diastolic and mean arterial pulse values as well as the pulse after blood pressure reading is completed."
    
    static let bgmHelpText = "The BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your glucose sensor.\nTap the Get Records button to read the history of glucose records."
    
    static let cgmHelpText = "The CGM (CONTINUOUS GLUCOSE MONITOR) profile allows you to connect to your continuous glucose sensor.\nTap the Start session button to begin reading records every minute (default frequency)"
    
    static let helpText: [NORServiceIds: String] = [.UART: uartHelpText,
                                                    .RSC: rscHelpText,
                                                    .Proximity: proximityHelpText,
                                                    .HTM: htmHelpText,
                                                    .HRM: hrmHelpText,
                                                    .CSC: cscHelpText,
                                                    .BPM: bpmHelpText,
                                                    .BGM: bgmHelpText,
                                                    .CGM: cgmHelpText]

    static func showAlert(title aTitle : String, andMessage aMessage: String){
        let alertView = UIAlertView(title: aTitle, message: aMessage, delegate: nil, cancelButtonTitle: "OK")
        alertView.show()
    }

    static func showBackgroundNotification(message aMessage : String){
        let localNotification = UILocalNotification()
        localNotification.alertAction   = "Show"
        localNotification.alertBody     = aMessage
        localNotification.hasAction     = false
        localNotification.fireDate      = NSDate(timeIntervalSinceNow: 1)
        localNotification.timeZone      = NSTimeZone.defaultTimeZone()
        localNotification.soundName     = UILocalNotificationDefaultSoundName
    }
    
    static func isApplicationInactive() -> Bool {
        let appState = UIApplication.sharedApplication().applicationState
        return appState != UIApplicationState.Active
    }
    
    static func getHelpTextForService(service aServiceId: NORServiceIds) -> String {
        return helpText[aServiceId]!
    }
}
