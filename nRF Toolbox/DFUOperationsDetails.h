//
//  DFUOperationsDetails.h
//  nRFDeviceFirmwareUpdate
//
//  Created by Kamran Saleem Soomro on 02/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Utility.h"

@interface DFUOperationsDetails : NSObject

@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;
@property (strong, nonatomic)CBCharacteristic *dfuPacketCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuControlPointCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuVersionCharacteristic;
@property (nonatomic)DfuFirmwareTypes dfuFirmwareType;

//defining public methods
-(void) enableNotification;
-(void) startDFU:(DfuFirmwareTypes)firmwareType;
-(void) startOldDFU;
-(void) writeFileSize:(uint32_t)firmwareSize;
-(void) writeFilesSizes:(uint32_t)softdeviceSize bootloaderSize:(uint32_t)bootloaderSize;
-(void) writeFileSizeForOldDFU:(uint32_t)firmwareSize;
-(void) enablePacketNotification;
-(void) receiveFirmwareImage;
-(void) validateFirmware;
-(void) activateAndReset;
-(void) resetSystem;

//Init Packet is included in new DFU in SDK 7.0
-(void) sendInitPacket:(NSURL *)metaDataURL;

//dfu Version characteristic is introduced in SDK 7.0
-(void)getDfuVersion;

//App can be set Accessory to DFU mode in SDK 7.0 in order to update firmware
-(void)resetAppToDFUMode;

-(void) setPeripheralAndOtherParameters:(CBPeripheral *)peripheral
                controlPointCharacteristic:(CBCharacteristic *)controlPointCharacteristic
                packetCharacteristic:(CBCharacteristic *)packetCharacteristic;

-(void) setPeripheralAndOtherParametersWithVersion:(CBPeripheral *)peripheral
             controlPointCharacteristic:(CBCharacteristic *)controlPointCharacteristic
                   packetCharacteristic:(CBCharacteristic *)packetCharacteristic
                  versionCharacteristic:(CBCharacteristic *)versionCharacteristic;

@end
