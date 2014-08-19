//
//  ScannedPeripheral.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ScannedPeripheral.h"

@implementation ScannedPeripheral
@synthesize peripheral;
@synthesize RSSI;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI
{
    ScannedPeripheral* value = [ScannedPeripheral alloc];
    value.peripheral = peripheral;
    value.RSSI = RSSI;
    return value;
}

-(NSString*) name
{
    NSString* name = [peripheral name];
    if (name == nil)
    {
        return @"No name";
    }
    return name;
}

-(BOOL)isEqual:(id)object
{
    ScannedPeripheral* other = (ScannedPeripheral*) object;
    return peripheral == other.peripheral;
}

@end
