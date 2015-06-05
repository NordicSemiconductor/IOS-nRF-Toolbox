//
//  BluetoothManager.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 04/06/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

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
