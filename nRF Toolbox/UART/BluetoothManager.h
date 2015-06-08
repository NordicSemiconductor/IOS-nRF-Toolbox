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

@protocol BluetoothManagerDelegate

-(void)didDeviceConnected:(NSString *)peripheralName;
-(void)didDeviceDisconnected;
-(void)didDiscoverUARTService:(CBService *)uartService;
-(void)didDiscoverRXCharacteristic:(CBCharacteristic *)rxCharacteristic;
-(void)didDiscoverTXCharacteristic:(CBCharacteristic *)txCharacteristic;
-(void)didReceiveTXNotification:(NSData *)data;
-(void)didError:(NSString *)errorMessage;

@end

@interface BluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

//Singleton Design pattern
+ (id)sharedInstance;

//set Delegate properties for UARTViewController
-(void)setUARTDelegate:(id<BluetoothManagerDelegate>)uartDelegate;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;

//Delegate properties for UARTViewController
@property (nonatomic, assign)id<BluetoothManagerDelegate> uartDelegate;

-(void)setBluetoothCentralManager:(CBCentralManager *)manager;
-(void)connectDevice:(CBPeripheral *)peripheral;
-(void)disconnectDevice;
-(void)writeRXValue:(NSString *)value;

@property (nonatomic, strong) CBUUID *UART_Service_UUID;
@property (nonatomic, strong) CBUUID *UART_RX_Characteristic_UUID;
@property (nonatomic, strong) CBUUID *UART_TX_Characteristic_UUID;

@property (strong, nonatomic)CBCharacteristic *uartRXCharacteristic;
@property (strong, nonatomic)CBCharacteristic *uartTXCharacteristic;


@end
