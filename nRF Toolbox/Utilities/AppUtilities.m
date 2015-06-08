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
    return [NSString stringWithFormat:@"-UART profile allows you to connect to your UART sensor.\n\n-You can send and receive short messages of 20 characters in total."];
}

+ (NSString *) getRSACHelpText {
    return [NSString stringWithFormat:@"-RSC (Running Speed and Cadence) profile allows you to connect to your activity sensor.\n\n-It reads speed and cadence values from the sensor and calculates trip distance if stride length is supported.\n\n-Strides count is calculated by using cadence and the time."];
}

+ (NSString *) getProximityHelpText {
    return [NSString stringWithFormat:@"-PROXIMITY profile allows you to connect to your Proximity sensor.\n\n-You can find your valuables attached with Proximity tag by pressing FindMe button on screen and you can find your phone by pressing relevant button on your tag.\n\n-A notification will appear on your phone screen when you go away from your connected tag."];
}

+ (NSString *) getHTSHelpText {
    return [NSString stringWithFormat:@"-HTM (Health Thermometer Monitor) profile allows you to connect to your Health Thermometer sensor.\n\n-It shows you the temperature value in Celisius and Fahrenheit units.\n\n-Default temperature unit is Celsius but you can set up unit in the iPhone Settings."];
}

+ (NSString *) getHRSHelpText {
    return [NSString stringWithFormat:@"-HRM (Heart Rate Monitor) profile allows you to connect to your Heart Rate sensor (f.e. a belt).\n\n-It shows you the current heart rate, location of the sensor and data history on the graph."];
}

+ (NSString *) getCSCHelpText {
    return [NSString stringWithFormat: @"-CSC (Cycling Speed and Cadence) profile allows you to connect to your bike activity sensor.\n\n-It reads wheel and crank data if they are supported by the sensor and calculates speed, cadence, total and trip distance and gear ratio.\n\n-Default wheel size is 29 inches but you can set up wheel size in the iPhone Settings."];
}

+ (NSString *) getBPMHelpText {
    return [NSString stringWithFormat:@"-BPM (Blood Pressure Monitor) profile allows you to connect to your Blood Pressure device.\n\n-It supports the cuff pressure notifications and displays systolic, diastolic and mean arterial pulse values as well as the pulse after blood pressure reading is completed."];
}

+ (NSString *) getBGMHelpText {
    return [NSString stringWithFormat:@"-BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your Glucose sensor.\n\n-You can read the history of glucose records."];
}

@end
