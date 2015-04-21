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

#import "BLEOperations.h"
#import "Utility.h"

@implementation BLEOperations

bool isDFUPacketCharacteristicFound, isDFUControlPointCharacteristic, isDFUVersionCharacteristicFound, isDFUServiceFound;
CBUUID *HR_Service_UUID;
CBUUID *HR_Location_Characteristic_UUID;
static NSString * const hrsServiceUUIDString = @"0000180D-0000-1000-8000-00805F9B34FB";
static NSString * const hrsSensorLocationCharacteristicUUIDString = @"00002A38-0000-1000-8000-00805F9B34FB";


-(BLEOperations *) initWithDelegate:(id<BLEOperationsDelegate>) delegate
{
    if (self = [super init])
    {
        self.bleDelegate = delegate;
        HR_Service_UUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
        HR_Location_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorLocationCharacteristicUUIDString];
    }
    return self;
}

-(void)setBluetoothCentralManager:(CBCentralManager *)manager
{
    self.centralManager = manager;
    self.centralManager.delegate = self;
}

-(void)connectDevice:(CBPeripheral *)peripheral
{
    self.bluetoothPeripheral = peripheral;
    self.bluetoothPeripheral.delegate = self;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

-(void)searchDFURequiredCharacteristics:(CBService *)service
{
    isDFUControlPointCharacteristic = NO;
    isDFUPacketCharacteristicFound = NO;
    isDFUVersionCharacteristicFound = NO;
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Found characteristic %@",characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuControlPointCharacteristicUUIDString]]) {
            NSLog(@"Control Point characteristic found");
            isDFUControlPointCharacteristic = YES;
            self.dfuControlPointCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuPacketCharacteristicUUIDString]]) {
            NSLog(@"Packet Characteristic is found");
            isDFUPacketCharacteristicFound = YES;
            self.dfuPacketCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuVersionCharacteritsicUUIDString]]) {
            NSLog(@"Version Characteristic is found");
            isDFUVersionCharacteristicFound = YES;
            self.dfuVersionCharacteristic = characteristic;
        }    }
}

#pragma mark - CentralManager delegates
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    [self.bluetoothPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral");
    [self.bleDelegate onDeviceDisconnected:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
    [self.bleDelegate onDeviceDisconnected:peripheral];
}

#pragma mark - CBPeripheral delegates

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    isDFUServiceFound = NO;
    NSLog(@"didDiscoverServices, found %lu services",(unsigned long)peripheral.services.count);
    for (CBService *service in peripheral.services) {
        NSLog(@"discovered service %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:dfuServiceUUIDString]]) {
            NSLog(@"DFU Service is found");
            isDFUServiceFound = YES;
        }
        [self.bluetoothPeripheral discoverCharacteristics:nil forService:service];
    }
    if (!isDFUServiceFound) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering service\n Message: Required DFU service not available on peripheral"];
        [self.centralManager cancelPeripheralConnection:peripheral];
        [self.bleDelegate onError:errorMessage];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService");
    if ([service.UUID isEqual:[CBUUID UUIDWithString:dfuServiceUUIDString]]) {
        [self searchDFURequiredCharacteristics:service];
        if (isDFUControlPointCharacteristic && isDFUPacketCharacteristicFound && isDFUVersionCharacteristicFound) {
            [self.bluetoothPeripheral readValueForCharacteristic:self.dfuVersionCharacteristic];
            [self.bleDelegate onDeviceConnectedWithVersion:self.bluetoothPeripheral
                                  withPacketCharacteristic:self.dfuPacketCharacteristic
                             andControlPointCharacteristic:self.dfuControlPointCharacteristic
                                  andVersionCharacteristic:self.dfuVersionCharacteristic];            
        }
        else if (isDFUControlPointCharacteristic && isDFUPacketCharacteristicFound && isDFUVersionCharacteristicFound == NO) {
            [self.bleDelegate onDeviceConnected:self.bluetoothPeripheral
                       withPacketCharacteristic:self.dfuPacketCharacteristic
                  andControlPointCharacteristic:self.dfuControlPointCharacteristic];
        }
        else {
            NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering characteristics\n Message: Required DFU characteristics are not available on peripheral"];
            [self.centralManager cancelPeripheralConnection:peripheral];
            [self.bleDelegate onError:errorMessage];
        }
    }
    else if ([service.UUID isEqual:HR_Service_UUID]) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
                NSLog(@"HR Position characteristic is found");
                [self.bluetoothPeripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic");
    if (error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error on BLE Notification\n Message: %@",[error localizedDescription]];
        NSLog(@"Error in Notification state: %@",[error localizedDescription]);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuVersionCharacteritsicUUIDString]]) {
            NSLog(@"Error in Reading DfuVersionCharacteritsic. Please enable Service Changed Indication in your firmware, reset Bluetooth from IOS Settings and then try again");
            errorMessage = [NSString stringWithFormat:@"Error on BLE Notification\n Message: %@\n Please enable Service Changed Indication in your firmware, reset Bluetooth from IOS Settings and then try again",[error localizedDescription]];
            [self.bleDelegate onReadDfuVersion:0];
        }
        [self.bleDelegate onError:errorMessage];
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuVersionCharacteritsicUUIDString]]) {
        const uint8_t *version = [characteristic.value bytes] ;
        NSLog(@"dfu Version Characteristic first byte is %d and second byte is %d",version[0],version[1]);        
        [self.bleDelegate onReadDfuVersion:version[0]];
    }
    else {
        NSLog(@"received notification %@",characteristic.value);
        [self.bleDelegate onReceivedNotification:characteristic.value];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"error in writing characteristic %@ and error %@",characteristic.UUID,[error localizedDescription]);
    }
    else {
        NSLog(@"didWriteValueForCharacteristic %@ and value %@",characteristic.UUID,characteristic.value);
    }
}


@end
