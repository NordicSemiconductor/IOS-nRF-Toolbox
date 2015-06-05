//
//  BluetoothManager.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 04/06/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "BluetoothManager.h"
#import "Constants.h"

@implementation BluetoothManager

+ (id)sharedInstance
{
    static BluetoothManager *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        self.UART_Service_UUID = [CBUUID UUIDWithString:uartServiceUUIDString];
        self.UART_TX_Characteristic_UUID = [CBUUID UUIDWithString:uartTXCharacteristicUUIDString];
        self.UART_RX_Characteristic_UUID = [CBUUID UUIDWithString:uartRXCharacteristicUUIDString];
    }
    return self;
}

-(void)setUARTDelegate:(id<BluetoothManagerDelegate>)uartDelegate
{
    self.uartDelegate = uartDelegate;
}

-(void)setLogDelegate:(id<BluetoothManagerDelegate>)logDelegate
{
    self.logDelegate = logDelegate;
}

-(void)setBluetoothCentralManager:(CBCentralManager *)manager
{
    if (manager) {
        self.centralManager = manager;
        self.centralManager.delegate = self;
    }
}

-(void)connectDevice:(CBPeripheral *)peripheral
{
    if (peripheral) {
        self.bluetoothPeripheral = peripheral;
        self.bluetoothPeripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)disconnectDevice
{
    if (self.bluetoothPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.bluetoothPeripheral];
    }
}

-(void)writeRXValue:(NSString *)value
{
    if (self.uartRXCharacteristic) {
        NSLog(@"writing command: %@ to UART peripheral: %@",value,self.bluetoothPeripheral.name);
        [self.bluetoothPeripheral writeValue:[value dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.uartRXCharacteristic type:CBCharacteristicWriteWithoutResponse];
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
    [self.uartDelegate didDeviceConnected:peripheral.name];
    [self.bluetoothPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral");
    [self.uartDelegate didDeviceDisconnected];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CBPeripheralDisconnectNotification" object:self];
    self.bluetoothPeripheral = nil;
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
    [self.uartDelegate didDeviceDisconnected];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CBPeripheralDisconnectNotification" object:self];
    self.bluetoothPeripheral = nil;
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    if (!error) {
        NSLog(@"services discovered %lu",(unsigned long)[peripheral.services count] );
        for (CBService *uartService in peripheral.services) {
            NSLog(@"service discovered: %@",uartService.UUID);
            if ([uartService.UUID isEqual:self.UART_Service_UUID])
            {
                NSLog(@"UART service found");
                [self.uartDelegate didDiscoverUARTService:uartService];
                [self.bluetoothPeripheral discoverCharacteristics:nil forService:uartService];
            }
        }
    } else {
        NSLog(@"error in discovering services on device: %@",self.bluetoothPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:self.UART_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:self.UART_TX_Characteristic_UUID]) {
                    NSLog(@"UART TX characteritsic is found");
                    [self.uartDelegate didDiscoverTXCharacteristic:characteristic];
                    [self.bluetoothPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
                else if ([characteristic.UUID isEqual:self.UART_RX_Characteristic_UUID]) {
                    NSLog(@"UART RX characteristic is found");
                    [self.uartDelegate didDiscoverRXCharacteristic:characteristic];
                    self.uartRXCharacteristic = characteristic;
                }
            }
        }
        
    } else {
        NSLog(@"error in discovering characteristic on device: %@",self.bluetoothPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            NSLog(@"received update from UART: %@, UUID: %@",characteristic.value,characteristic.UUID);
            if (characteristic.value.length != 0) {
                [self.uartDelegate didReceiveTXNotification:characteristic.value];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBPeripheralTXNotification" object:self];
            }
        }
        else {
            NSLog(@"error in update UART value");
        }
    });
}

@end
