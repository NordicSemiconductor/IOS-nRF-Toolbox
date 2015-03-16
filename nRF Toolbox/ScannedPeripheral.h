//
//  ScannedPeripheral.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScannedPeripheral : NSObject

@property (strong, nonatomic) CBPeripheral* peripheral;
@property (assign, nonatomic) int RSSI;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI;

- (NSString*) name;

@end
