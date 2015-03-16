//
//  ScannerDelegate.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol ScannerDelegate <NSObject>

- (void) centralManager:(CBCentralManager*) manager didPeripheralSelected:(CBPeripheral*) peripheral;

@end
