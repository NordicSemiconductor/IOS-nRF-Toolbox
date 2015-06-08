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

int  PACKETS_NOTIFICATION_INTERVAL = 10;
int const PACKET_SIZE = 20;

NSString* const FIRMWARE_TYPE_SOFTDEVICE = @"softdevice";
NSString* const FIRMWARE_TYPE_BOOTLOADER = @"bootloader";
NSString* const FIRMWARE_TYPE_APPLICATION = @"application";
NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER = @"softdevice and bootloader";

+ (NSString *) getDFUHelpText
{
    return [NSString stringWithFormat:@"-The Device Firmware Update (DFU) app that is compatible with Nordic Semiconductor nRF51822 devices that have the S110 SoftDevice and bootloader enabled.\n\n-It allows to upload new application onto the device over-the-air (OTA).\n\n-The DFU discovers supported DFU devices, connects to them, and uploads user selected firmware applications to the device.\n\n-Default number of Packet Receipt Notification is 10 but you can set up other number in the iPhone Settings.\n\n-(New) Bin format is also supported in this version.\n\n-(New) This version supports Nordic Semiconductor softdevice 7.1 and SDK 7.1 and it is backword compatible. \n\n-(New) In SDK 7.0 and above initPacket is sent in a file (.dat) in addition to firmware file.\n\n-(New) For Application update application.hex or application.bin and application.dat is required inside a zip file.\n\n-(New) For Bootloader update bootloader.hex or bootloader.bin and bootloader.dat is required inside a zip file.\n\n-(New) For Softdevice update softdevice.hex or softdevice.bin and softdevice.dat is required.\n\n-(New) For updating both softdevice and bootloader system.dat is required in addition."];
}

+ (NSString *) getEmptyUserFilesText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with Hex, Bin and Zip extensions from Emails and iTunes.\n\n-User added files will be appeared here.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files."];
}

+ (NSString *) getDFUAppFileHelpText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with Hex, Bin and Zip extensions from Emails and iTunes.\n\n-User added files will be appeared on tab User Files.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files.\n\n- In order to add files from Emails:\n   1. Attach file to your email.\n   2.Open your email on your iPhone.\n   3.Long click on attached file and then select Open in nRF Toolbox."];
}

+ (NSString *) getEmptyFolderText
{
    return @"There are no Hex, Bin or Zip files found inside selected folder.";
}



+ (NSArray *) getFirmwareTypes
{
    static NSArray *events;
    if (events == nil) {
        events = @[FIRMWARE_TYPE_SOFTDEVICE, FIRMWARE_TYPE_BOOTLOADER, FIRMWARE_TYPE_APPLICATION, FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER];
    }
    return events;
}

+ (NSString *) stringFileExtension:(enumFileExtension)fileExtension
{
    switch (fileExtension) {
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
    if (applicationState == UIApplicationStateInactive || applicationState == UIApplicationStateBackground) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
