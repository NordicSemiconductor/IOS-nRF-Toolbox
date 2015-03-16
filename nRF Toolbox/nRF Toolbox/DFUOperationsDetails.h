//
//  DFUOperationsDetails.h
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 02/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Utility.h"

@interface DFUOperationsDetails : NSObject

@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;
@property (strong, nonatomic)CBCharacteristic *dfuPacketCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuControlPointCharacteristic;
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

-(void) setPeripheralAndOtherParameters:(CBPeripheral *)peripheral controlPointCharacteristic:(CBCharacteristic *)controlPointCharacteristic packetCharacteristic:(CBCharacteristic *)PacketCharacteristic;

@end
