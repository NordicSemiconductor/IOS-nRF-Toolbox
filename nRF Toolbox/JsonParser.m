//
//  JsonParser.m
//  TestJson
//
//  Created by Kamran Saleem Soomro on 12/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "JsonParser.h"


@implementation JsonParser

-(InitData *)parseJson:(NSData *)data
{    
    if(data) {
        NSError *error;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) {
            NSLog(@"JSON parser failed %@",error);
            return nil;
        }
        if ([jsonDictionary isKindOfClass:[NSDictionary class]]) {
            NSLog(@"JSON has valid top level dictionary");
            NSString *manifestKey = @"manifest";
            id manifestValue = [jsonDictionary objectForKey:manifestKey];
            self.packetData = [[InitData alloc]init];
            for (id key in manifestValue) {
                id value = [manifestValue objectForKey:key];
                if ([key isEqualToString:@"application"]) {
                    self.packetData.firmwareType = APPLICATION;
                    [self processManifest:value];
                }
                else if ([key isEqualToString:@"bootloader"])
                {
                    self.packetData.firmwareType = BOOTLOADER;
                    [self processManifest:value];
                }
                else if ([key isEqualToString:@"softdevice"])
                {
                    self.packetData.firmwareType = SOFTDEVICE;
                    [self processManifest:value];
                }
                else if ([key isEqualToString:@"softdevice_bootloader"])
                {
                    self.packetData.firmwareType = SOFTDEVICE_AND_BOOTLOADER;
                    [self processManifest:value];
                }
            }
            return self.packetData;
        }
        else {
            NSLog(@"Error. Json dont have top level dictionary");
            return nil;
        }
    }
    else {
        NSLog(@"data is empty");
        return nil;
    }
    
}

-(void)processManifest:(id)value
{
    for (id firmwareKey in value) {
        if ([firmwareKey isEqualToString:@"init_packet_data"]) {
            [self processInitPacketData:[value objectForKey:firmwareKey]];
        }
        else if ([firmwareKey isEqualToString:@"bin_file"]) {
            self.packetData.firmwareBinFileName = [value objectForKey:firmwareKey];
        }
        else if ([firmwareKey isEqualToString:@"dat_file"]) {
            self.packetData.firmwareDatFileName = [value objectForKey:firmwareKey];
        }
        else if ([firmwareKey isEqualToString:@"bl_size"]) {
            self.packetData.bootloaderSize = (int)[[value valueForKey:firmwareKey] integerValue];
        }
        else if ([firmwareKey isEqualToString:@"sd_size"]) {
            self.packetData.softdeviceSize = (int)[[value valueForKey:firmwareKey] integerValue];
        }
    }
}

-(void)processInitPacketData:(id)value
{
    for (id initPacketDataKey in value) {
        if ([initPacketDataKey isEqualToString:@"application_version"]) {
            self.packetData.applicationVersion = (uint32_t)[[value valueForKey:initPacketDataKey] integerValue];
        }
        else if ([initPacketDataKey isEqualToString:@"device_revision"]) {
            self.packetData.deviceRevision = (uint16_t)[[value valueForKey:initPacketDataKey] integerValue];
        }
        else if ([initPacketDataKey isEqualToString:@"device_type"]) {
            self.packetData.deviceType = (uint16_t)[[value valueForKey:initPacketDataKey] integerValue];
        }
        else if ([initPacketDataKey isEqualToString:@"firmware_crc16"]) {
            self.packetData.firmwareCRC = (uint16_t)[[value valueForKey:initPacketDataKey] integerValue];
        }
        else if ([initPacketDataKey isEqualToString:@"softdevice_req"]) {
            self.packetData.softdeviceRequired = [value objectForKey:initPacketDataKey];
        }
    }
}
@end
