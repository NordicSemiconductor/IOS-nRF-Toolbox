//
//  AppUtilities.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 09/04/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

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
    return [NSString stringWithFormat:@"The BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your Glucose sensor. By tapping the Get Records button you may read the history of glucose records."];
}

@end
