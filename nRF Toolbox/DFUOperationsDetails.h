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
