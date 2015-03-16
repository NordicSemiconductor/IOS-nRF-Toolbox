//
//  Utility.m
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 22/05/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "Utility.h"

@implementation Utility

NSString * const dfuServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
NSString * const dfuControlPointCharacteristicUUIDString = @"00001531-1212-EFDE-1523-785FEABCD123";
NSString * const dfuPacketCharacteristicUUIDString = @"00001532-1212-EFDE-1523-785FEABCD123";

int  PACKETS_NOTIFICATION_INTERVAL = 10;
int const PACKET_SIZE = 20;

NSString* const FIRMWARE_TYPE_SOFTDEVICE = @"softdevice";
NSString* const FIRMWARE_TYPE_BOOTLOADER = @"bootloader";
NSString* const FIRMWARE_TYPE_APPLICATION = @"application";
NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER = @"softdevice and bootloader";

+ (NSString *) getDFUHelpText
{
    return [NSString stringWithFormat:@"-The Device Firmware Update (DFU) app that is compatible with Nordic Semiconductor nRF51822 devices that have the S110 SoftDevice and bootloader enabled.\n\n-It allows to upload new application onto the device over-the-air (OTA).\n\n-The DFU discovers supported DFU devices, connects to them, and uploads user selected firmware applications to the device.\n\n-Default number of Packet Receipt Notification is 10 but you can set up other number in the iPhone Settings.\n\n-(New) Having NordicSemiconductor devices with Softdevice 7.0.0 and new Bootloader in SDK 6.0, It now allows to upload softdevice, bootloader and application.\n\n-(New) In order to upload softdevice and bootloader together, Zip file having inside softdevice.hex and bootloader.hex is required."];
}

+ (NSString *) getEmptyUserFilesText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with HEX and ZIP extensions from Emails and iTunes.\n\n-User added files will be appeared here.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files."];
}

+ (NSString *) getDFUAppFileHelpText
{
    return [NSString stringWithFormat:@"-User can add Folders and Files with HEX and ZIP extensions from Emails and iTunes.\n\n-User added files will be appeared on tab User Files.\n\n- In order to add files from iTunes:\n   1. Open iTunes on your PC and connect iPhone to it.\n   2.On the left, under Devices select your iPhone.\n   3.on the top, select tab Apps.\n   4. on the bottom, under File Sharing select app nRF Toolbox and then add files.\n\n- In order to add files from Emails:\n   1. Attach file to your email.\n   2.Open your email on your iPhone.\n   3.Long click on attached file and then select Open in nRF Toolbox."];
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


@end
