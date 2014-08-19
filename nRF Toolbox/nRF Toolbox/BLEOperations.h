//
//  BLEOperations.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class BLEOperations;

@protocol BLEOperationsDelegate

-(void)onDeviceConnected:(CBPeripheral *)peripheral withPacketCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic andControlPointCharacteristic:(CBCharacteristic *)dfuControlPointCharacteristic;
-(void)onDeviceDisconnected:(CBPeripheral *)peripheral;
-(void)onReceivedNotification:(NSData *)data;
-(void)onError:(NSString *)errorMessage;

@end

@interface BLEOperations : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;
@property (strong, nonatomic)CBCharacteristic *dfuPacketCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuControlPointCharacteristic;

-(BLEOperations *) initWithDelegate:(id<BLEOperationsDelegate>) delegate;

//define delegate property
@property (nonatomic, assign)id<BLEOperationsDelegate> bleDelegate;

-(void)setBluetoothCentralManager:(CBCentralManager *)manager;
-(void)connectDevice:(CBPeripheral *)peripheral;

@end
