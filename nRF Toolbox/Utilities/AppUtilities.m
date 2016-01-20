/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppUtilities.h"

@implementation AppUtilities

+ (void) showAlert:(NSString *)title alertMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

+(void)showBackgroundNotification:(NSString *)message {
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.alertAction = @"Show";
    notification.alertBody = message;
    notification.hasAction = NO;
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.timeZone = [NSTimeZone  defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

+ (BOOL)isApplicationStateInactiveORBackground {
    UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
    if (applicationState == UIApplicationStateInactive || applicationState == UIApplicationStateBackground) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (NSString *) getUARTHelpText {
    return [NSString stringWithFormat:@"This profile allows you to connect to a device that support Nordic's UART service. The service allows you to send and receive short messages of 20 bytes in total.\n\nThe main screen contains 9 programmable buttons. Use the Edit button to edit a command or an icon assigned to each button. Unused buttons may be hidden.\n\nTap the Show Log button to see the conversation or to send a custom message."];
}

+ (NSString *) getRSACHelpText {
    return [NSString stringWithFormat:@" The RSC (Running Speed and Cadence) profile allows you to connect to your activity sensor. It reads speed and cadence values from the sensor and calculates trip distance if stride length is supported. Strides count is calculated by using cadence and the time."];
}

+ (NSString *) getProximityHelpText {
    return [NSString stringWithFormat:@"The PROXIMITY profile allows you to connect to your Proximity sensor. Later on you can find your valuables attached with Proximity tag by pressing the FindMe button on the screen or your phone by pressing relevant button on your tag. A notification will appear on your phone screen when you go away from your connected tag."];
}

+ (NSString *) getHTSHelpText {
    return [NSString stringWithFormat:@"The HTM (Health Thermometer Monitor) profile allows you to connect to your Health Thermometer sensor. It displays the temperature value in Celsius or Fahrenheit degrees."];
}

+ (NSString *) getHRSHelpText {
    return [NSString stringWithFormat:@"The HRM (Heart Rate Monitor) profile allows you to connect and read data from your Heart Rate sensor (eg. a belt). It shows the current heart rate, location of the sensor and displays the historical data on a graph."];
}

+ (NSString *) getCSCHelpText {
    return [NSString stringWithFormat: @"The CSC (Cycling Speed and Cadence) profile allows you to connect to your bike activity sensor. It reads wheel and crank data if the sensor supports it, and calculates speed, cadence, total and trip distance and gear ratio. The default wheel size is set to 29 inches but you can set up wheel size in the Settings."];
}

+ (NSString *) getBPMHelpText {
    return [NSString stringWithFormat:@"The BPM (Blood Pressure Monitor) profile allows you to connect to your Blood Pressure device. It supports the cuff pressure notifications and displays systolic, diastolic and mean arterial pulse values as well as the pulse after blood pressure reading is completed."];
}

+ (NSString *) getBGMHelpText {
    return [NSString stringWithFormat:@"The BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your Glucose sensor.\nTap the Get Records button to read the history of glucose records."];
}

@end
