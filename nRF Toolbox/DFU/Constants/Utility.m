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

#import "Utility.h"

@implementation Utility

NSString * const dfuServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
NSString * const dfuControlPointCharacteristicUUIDString = @"00001531-1212-EFDE-1523-785FEABCD123";
NSString * const dfuPacketCharacteristicUUIDString = @"00001532-1212-EFDE-1523-785FEABCD123";
NSString * const dfuVersionCharacteritsicUUIDString = @"00001534-1212-EFDE-1523-785FEABCD123";

NSString * const ANCSServiceUUIDString = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";
NSString * const TimerServiceUUIDString = @"1805";

int PACKETS_NOTIFICATION_INTERVAL = 10;
int const PACKET_SIZE = 20;

NSString* const FIRMWARE_TYPE_SOFTDEVICE = @"Softdevice";
NSString* const FIRMWARE_TYPE_BOOTLOADER = @"Bootloader";
NSString* const FIRMWARE_TYPE_APPLICATION = @"Application";
NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER = @"Softdevice and bootloader";

+ (NSString *) getDFUHelpText
{
    return [NSString stringWithFormat:@"The Device Firmware Update (DFU) profile allows to upload a new application, Soft Device or bootloader onto the device over-the-air (OTA). It is compatible with nRF5x devices, from Nordic Semiconductor, that have the S110, S130 or S132 SoftDevice and the DFU bootloader enabled. \n\nDefault number of Packet Receipt Notification is 10 and can changed in the Settings. For more information about the DFU check the documentation."];
}

+ (NSString *) getEmptyUserFilesText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with Hex, Bin and Zip extensions from Emails and iTunes.\n\n-User added files will be appeared here.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files."];
}

+ (NSString *) getDFUAppFileHelpText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with Hex, Bin and Zip extensions from Emails and iTunes.\n\n-User added files will be appeared on tab User Files.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files.\n\n- In order to add files from Emails:\n   1. Attach file to your email.\n   2.Open your email on your iPhone.\n   3.Long click on attached file and then select Open in nRF Toolbox."];
}

+ (NSString *) stringFileExtension:(enumFileExtension)fileExtension
{
    switch (fileExtension)
    {
        case HEX:
            return @"hex";
        case BIN:
            return @"bin";
        case ZIP:
            return @"zip";
            
        default:
            return nil;
    }
}

+ (void)showAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DFU" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

+(void)showBackgroundNotification:(NSString *)message
{
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
    return applicationState == UIApplicationStateInactive || applicationState == UIApplicationStateBackground;
}

@end
