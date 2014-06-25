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

int const PACKETS_NOTIFICATION_INTERVAL = 10;
int const PACKET_SIZE = 20;

NSString* const FIRMWARE_TYPE_SOFTDEVICE = @"softdevice";
NSString* const FIRMWARE_TYPE_BOOTLOADER = @"bootloader";
NSString* const FIRMWARE_TYPE_APPLICATION = @"application";
NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER = @"softdevice and bootloader";

+ (NSArray *) getFirmwareTypes
{
    static NSArray *events;
    if (events == nil) {
        events = @[FIRMWARE_TYPE_SOFTDEVICE, FIRMWARE_TYPE_BOOTLOADER, FIRMWARE_TYPE_APPLICATION, FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER];
    }
    return events;
}

@end
