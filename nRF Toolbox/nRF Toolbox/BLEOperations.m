//
//  BLEOperations.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "BLEOperations.h"
#import "Utility.h"

@implementation BLEOperations

bool isDFUPacketCharacteristicFound, isDFUControlPointCharacteristic;

-(BLEOperations *) initWithDelegate:(id<BLEOperationsDelegate>) delegate
{
    if (self = [super init])
    {
        self.bleDelegate = delegate;        
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
    }
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
    NSLog(@"didDiscoverServices");
    for (CBService *service in peripheral.services) {
        NSLog(@"discovered service %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:dfuServiceUUIDString]]) {
            NSLog(@"DFU Service is found");
            [self.bluetoothPeripheral discoverCharacteristics:nil forService:service];
            return;
        }
    }
    NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering service\n Message: Required DFU service not available on peripheral"];
    [self.centralManager cancelPeripheralConnection:peripheral];
    [self.bleDelegate onError:errorMessage];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService");
    [self searchDFURequiredCharacteristics:service];
    if (isDFUControlPointCharacteristic && isDFUPacketCharacteristicFound) {        
        [self.bleDelegate onDeviceConnected:self.bluetoothPeripheral withPacketCharacteristic:self.dfuPacketCharacteristic andControlPointCharacteristic:self.dfuControlPointCharacteristic];
    }
    else {
        NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering characteristics\n Message: Required DFU characteristics are not available on peripheral"];
        [self.centralManager cancelPeripheralConnection:peripheral];
        [self.bleDelegate onError:errorMessage];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic");
    if (error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error on BLE Notification\n Message: %@",[error localizedDescription]];
        NSLog(@"Error in Notification state: %@",[error localizedDescription]);
        [self.bleDelegate onError:errorMessage];
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
        /*NSString *errorMessage = [NSString stringWithFormat:@"Error on Writing Characteristic %@\n Message: %@",characteristic.UUID,[error localizedDescription]];
         [dfuDelegate onError:errorMessage];*/
        
    }
    else {
        NSLog(@"didWriteValueForCharacteristic %@ and value %@",characteristic.UUID,characteristic.value);
    }
}


@end
