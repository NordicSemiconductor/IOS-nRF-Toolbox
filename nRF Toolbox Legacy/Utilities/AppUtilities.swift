/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

enum ServiceIds : UInt8 {
    case uart       = 0
    case rsc        = 1
    case proximity  = 2
    case htm        = 3
    case hrm        = 4
    case csc        = 5
    case bpm        = 6
    case bgm        = 7
    case cgm        = 8
    case homekit    = 9
}

class AppUtilities: NSObject {

    static let iOSDFULibraryVersion = "4.5.1"

    static let uartHelpText = "This profile allows you to connect to a device that support Nordic's UART service. The service allows you to send and receive String messages.\n\nThe main screen contains 9 programmable buttons. Use the Edit button to edit a command or an icon assigned to each button. Unused buttons may be hidden.\n\nTap the Show Log button to see the conversation or to send a custom message."
    
    static let rscHelpText  = "The RSC (Running Speed and Cadence) profile allows you to connect to your activity sensor. It reads speed and cadence values from the sensor and calculates trip distance if stride length is supported. Strides count is calculated by using cadence and the time."
    
    static let proximityHelpText = "The PROXIMITY profile allows you to connect to your Proximity sensor. Later on you can find your valuables attached with Proximity tag by pressing the FindMe button on the screen or your phone by pressing relevant button on your tag. A notification will appear on your phone screen when you go away from your connected tag."
    

    static let htmHelpText = "The HTM (Health Thermometer Monitor) profile allows you to connect to your Health Thermometer sensor. It displays the temperature value in Celsius or Fahrenheit degrees."

    static let hrmHelpText = "The HRM (Heart Rate Monitor) profile allows you to connect and read data from your Heart Rate sensor (eg. a belt). It shows the current heart rate, location of the sensor and displays the historical data on a graph."

    static let cscHelpText = "The CSC (Cycling Speed and Cadence) profile allows you to connect to your bike activity sensor. It reads wheel and crank data if the sensor supports it, and calculates speed, cadence, total and trip distance and gear ratio. The default wheel size is set to 29 inches but you can set up wheel size in the Settings."
    
    static let bpmHelpText = "The BPM (Blood Pressure Monitor) profile allows you to connect to your Blood Pressure device. It supports the cuff pressure notifications and displays systolic, diastolic and mean arterial pulse values as well as the pulse after blood pressure reading is completed."
    
    static let bgmHelpText = "The BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your glucose sensor.\nTap the Get Records button to read the history of glucose records."
    
    static let cgmHelpText = "The CGM (CONTINUOUS GLUCOSE MONITOR) profile allows you to connect to your continuous glucose sensor.\nTap the Start session button to begin reading records every minute (default frequency)"
    
    static let homeKitHelpText = "The HomeKit profile allows you to connect to your HomeKit compatible accessories.\nTap the Add Accessory button to browse new accessories or select an accessory from the ones already configured. you will be able to browse the services and characteristics for this accessory and put in OTA DFU mode."
    
    static let helpText: [ServiceIds: String] = [.uart: uartHelpText,
                                                    .rsc: rscHelpText,
                                                    .proximity: proximityHelpText,
                                                    .htm: htmHelpText,
                                                    .hrm: hrmHelpText,
                                                    .csc: cscHelpText,
                                                    .bpm: bpmHelpText,
                                                    .bgm: bgmHelpText,
                                                    .cgm: cgmHelpText,
                                                    .homekit: homeKitHelpText]

    static func showAlert(title aTitle : String, andMessage aMessage: String, from viewController: UIViewController) {
        let alertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alertView, animated: true)
    }

    static func showBackgroundNotification(title: String, message: String){
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = message

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Identifier<UNNotification>.notification.string, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    static func requestNotificationAuthorization(handler: @escaping (Bool, Error?) -> ()) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: handler)
    }
    
    static func isApplicationInactive() -> Bool {
        let appState = UIApplication.shared.applicationState
        return appState != .active
    }
    
    static func getHelpTextForService(service aServiceId: ServiceIds) -> String {
        return helpText[aServiceId]!
    }
}
