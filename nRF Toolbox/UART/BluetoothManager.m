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

#import "BluetoothManager.h"
#import "Constants.h"
#import "NSDataAsHex.h"

@interface BluetoothManager () {
    CBUUID *UART_Service_UUID;
    CBUUID *UART_RX_Characteristic_UUID;
    CBUUID *UART_TX_Characteristic_UUID;
}

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *bluetoothPeripheral;

@property (nonatomic, strong) CBCharacteristic *uartRXCharacteristic;

@end

@implementation BluetoothManager

@synthesize delegate;
@synthesize logger;
@synthesize centralManager;
@synthesize bluetoothPeripheral;

-(id)initWithManager:(CBCentralManager *)manager
{
    if (self = [super init])
    {
        UART_Service_UUID = [CBUUID UUIDWithString:uartServiceUUIDString];
        UART_TX_Characteristic_UUID = [CBUUID UUIDWithString:uartTXCharacteristicUUIDString];
        UART_RX_Characteristic_UUID = [CBUUID UUIDWithString:uartRXCharacteristicUUIDString];
        
        centralManager = manager;
        centralManager.delegate = self;
    }
    return self;
}

# pragma mark - Logger API

-(void)log:(LogLevel)level message:(NSString *)message
{
    if (logger)
    {
        [logger log:level message:message];
    }
}

-(void)logError:(NSError *)error
{
    if (logger)
    {
        [logger log:Error message:[NSString stringWithFormat:@"Error %ld: %@", (long) error.code, [error.userInfo objectForKey:NSLocalizedDescriptionKey]]];
    }
}

#pragma mark - BluetoothManager API

-(void)connectDevice:(CBPeripheral *)peripheral
{
    if (peripheral)
    {
        // we assign the bluetoothPeripheral property after we establish a connection, in the callback
        
        [self log:Verbose message:[NSString stringWithFormat:@"Connecting to %@...", peripheral.name]];
        [self log:Debug message:@"[centralManager connectPeripheral:peripheral options:nil]"];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)disconnectDevice
{
    if (self.bluetoothPeripheral)
    {
        [self log:Verbose message:@"Disconnecting..."];
        [self log:Debug message:@"[centralManager cancelPeripheralConnection:peripheral]"];
        [self.centralManager cancelPeripheralConnection:self.bluetoothPeripheral];
    }
}

-(BOOL)isConnected
{
    return bluetoothPeripheral != nil;
}

-(void)send:(NSString *)text
{
    /*
     * This method sends the given test to the UART RX characteristic.
     * Depending on whether the characteristic has the Write Without Response or Write properties the behaviour is different.
     * In the latter case the Long Write may be used. To enable it you have to change the flag below.
     * Otherwise, in both cases, texts longer than 20 bytes (not characters) will be splitted into up-to 20-byte packets.
     */
    
    if (self.uartRXCharacteristic)
    {
        // For testing:
        // text = @"bebygdeååsldkdædådldldpdkdnr rjrnrnrknrrkr"; <- this text will be splited into 19, 20, 7-bytes packets
        
        // Check what kind of Write Type is supported. By default it will try Without Response.
        CBCharacteristicWriteType type = CBCharacteristicWriteWithoutResponse;
        // If the Property Write is set, it will change to Write Request
        if ((self.uartRXCharacteristic.properties & CBCharacteristicPropertyWrite) > 0)
        {
            type = CBCharacteristicWriteWithResponse;
        }
        
        // In case of Write Without Response the text needs to be splited in up-to 20-bytes packets.
        // When Write Request (with response) is used, the Long Write may be used. It will be handled automatically by the iOS, but must be supported on the device side.
        // If your device does support Long Write, change the flag here.
        BOOL longWriteSupported = NO;
        
        // The following code will split the text to packets
        char* buffer = (char*) [text UTF8String];
        unsigned long len = [[text dataUsingEncoding:NSUTF8StringEncoding] length];
        
        while (buffer)
        {
            NSString *part;
            
            if (len > 20 && (type == CBCharacteristicWriteWithoutResponse || !longWriteSupported))
            {
                // If the text contains national letters they may be 2-byte long. It may happen that only 19 bytes can be send so that non of them is splited into 2 packets.
                NSMutableString* builder = [[NSMutableString alloc] initWithBytes:buffer length:20 encoding:NSUTF8StringEncoding];
                if (builder)
                {
                    // A 20-bute string has been created successfully
                    buffer += 20;
                    len -= 20;
                }
                else
                {
                    // We have to create 19-byte string. Let's ignore some stranger UTF-8 characters that have more than 2 bytes...
                    builder = [[NSMutableString alloc] initWithBytes:buffer length:19 encoding:NSUTF8StringEncoding];
                    buffer += 19;
                    len -= 19;
                }
                
                part = [NSString stringWithString:builder];
            }
            else
            {
                // If the remaining part is shorter or equal than 20 bytes - send it all
                part = [NSString stringWithUTF8String:buffer];
                buffer = nil;
            }
            [self send:part withType:type];
        }
    }
}

/*!
 * Sends the given text to the UART RX characteristic using the given write type.
 */
-(void)send:(NSString *)text withType:(CBCharacteristicWriteType) type
{
    NSString* typeAsString = @"CBCharacteristicWriteWithoutResponse";
    if ((self.uartRXCharacteristic.properties & CBCharacteristicPropertyWrite) > 0)
    {
        typeAsString = @"CBCharacteristicWriteWithResponse";
    }
    
    // Convert string to NSData
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    // Do some logging..
    [self log:Verbose message:[NSString stringWithFormat:@"Writing to characteristic %@", UART_RX_Characteristic_UUID.UUIDString]];
    [self log:Debug message:[NSString stringWithFormat:@"[centralManager writeValue:0x%@ forCharacteristic:%@ type:%@]", [data hexadecimalStringWithDashes:NO], UART_RX_Characteristic_UUID.UUIDString, typeAsString]];
    
    // Send data to RX characteristic
    [self.bluetoothPeripheral writeValue:data forCharacteristic:self.uartRXCharacteristic type:type];
    
    // The transmitted data are not available after the method returns. We have to log the text here.
    // The callback peripheral:didWriteValueForCharacteristic:error: is called only when the Write Request type was used,
    // but even if, the data are not available there.
    [self log:App message:[NSString stringWithFormat:@"\"%@\" sent", text]];
}

#pragma mark - CentralManager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Central Manager did update state");
    NSString* state;
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            state = @"Powered ON";
            break;
            
        case CBCentralManagerStatePoweredOff:
            state = @"Powered OFF";
            break;
            
        case CBCentralManagerStateResetting:
            state = @"Resetting";
            break;
            
        case CBCentralManagerStateUnauthorized:
            state = @"Unauthorized";
            break;
            
        case CBCentralManagerStateUnsupported:
            state = @"Unsupported";
            break;
            
        case CBCentralManagerStateUnknown:
            state = @"Unknown";
            break;
    }
    [self log:Debug message:[NSString stringWithFormat:@"[Callback] Central Manager did update state to: %@", state]];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral connected");
    [self log:Debug message:@"[Callback] Central Manager did connect peripheral"];
    [self log:Info message:[NSString stringWithFormat:@"Connected to %@", peripheral.name]];
    
    bluetoothPeripheral = peripheral;
    bluetoothPeripheral.delegate = self;
    [delegate didDeviceConnected:peripheral.name];
    
    // Try to discover UART service
    [self log:Verbose message:@"Discovering services..."];
    [self log:Debug message:[NSString stringWithFormat:@"[peripheral discoverServices:@[%@]]", UART_Service_UUID.UUIDString]];
    [peripheral discoverServices:@[UART_Service_UUID]];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral disconnected");
    if (error)
    {
        [self log:Debug message:@"[Callback] Central Manager did disconnect peripheral"];
        [self logError:error];
    }
    else
    {
        [self log:Debug message:@"[Callback] Central Manager did disconnect peripheral without error"];
        [self log:Info message:@"Disconnected"];
    }
    
    [delegate didDeviceDisconnected];
    bluetoothPeripheral.delegate = nil;
    bluetoothPeripheral = nil;
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect peripheral");
    if (error)
    {
        [self log:Debug message:@"[Callback] Central Manager did fail to connect peripheral"];
        [self logError:error];
    }
    else
    {
        [self log:Debug message:@"[Callback] Central Manager did fail to connect peripheral without error"];
    }
    
    [delegate didDeviceDisconnected];
    bluetoothPeripheral.delegate = nil;
    bluetoothPeripheral = nil;
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [self log:Warning message:@"Service discovery failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        [self log:Info message:@"Services discovered"];
    
        for (CBService *uartService in peripheral.services)
        {
            if ([uartService.UUID isEqual:UART_Service_UUID])
            {
                [self log:Verbose message:@"Nordic UART Service found"];
                [self log:Verbose message:@"Discovering characterstics..."];
                [self log:Debug message:[NSString stringWithFormat:@"[peripheral discoverCharacteristics:nil forService:%@]", uartService.UUID.UUIDString]];
                [bluetoothPeripheral discoverCharacteristics:nil forService:uartService];
                return;
            }
        }
        
        // If the UART service has not been found...
        [self log:Warning message:@"UART service not found. Try to turn Bluetooth OFF and ON again to clear cache."];
        [delegate deviceNotSupported];
        
        [self disconnectDevice];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        [self log:Warning message:@"Characteristics discovery failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        [self log:Info message:@"Characteristics discovered"];
        
        if ([service.UUID isEqual:UART_Service_UUID]) {
            CBCharacteristic *txCharacteristic = nil;
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:UART_TX_Characteristic_UUID])
                {
                    [self log:Verbose message:@"TX Characteristic found"];
                    txCharacteristic = characteristic;
                }
                else if ([characteristic.UUID isEqual:UART_RX_Characteristic_UUID])
                {
                    [self log:Verbose message:@"RX Characteristic found"];
                    self.uartRXCharacteristic = characteristic;
                }
            }
            
            // Enable notifications on TX characteristic
            if (txCharacteristic && self.uartRXCharacteristic)
            {
                [self log:Verbose message:[NSString stringWithFormat:@"Enabling notifications for %@", txCharacteristic.UUID.UUIDString]];
                [self log:Debug message:[NSString stringWithFormat:@"[peripheral setNotifyValue:YES forCharacteristic:%@]", txCharacteristic.UUID.UUIDString]];
                [bluetoothPeripheral setNotifyValue:YES forCharacteristic:txCharacteristic];
            }
            else
            {
                [self log:Warning message:@"UART service does not have required characteristics. Try to turn Bluetooth OFF and ON again to clear cache."];
                [delegate deviceNotSupported];
                
                [self disconnectDevice];
            }
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [self log:Warning message:@"Enabling notifications failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        if ([characteristic isNotifying])
        {
            [self log:Info message:[NSString stringWithFormat:@"Notifications enabled for characteristic %@", characteristic.UUID.UUIDString]];
        }
        else
        {
            [self log:Info message:[NSString stringWithFormat:@"Notifications disabled for characteristic %@", characteristic.UUID.UUIDString]];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // This method is called only if the message is sent With Response.
    if (error)
    {
        [self log:Warning message:@"Writing characteristic value failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        [self log:Info message:[NSString stringWithFormat:@"Data written to %@", characteristic.UUID.UUIDString]];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
    if (error)
    {
        [self log:Warning message:@"Writing descriptor value failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        [self log:Info message:[NSString stringWithFormat:@"Data written to descr. %@", descriptor.UUID.UUIDString]];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [self log:Warning message:@"Updating characteristic value failed"];
        [self logError:error];
        
        // TODO disconnect?
    }
    else
    {
        [self log:Info message:[NSString stringWithFormat:@"Notification received from %@, value: (0x) %@",
                                characteristic.UUID.UUIDString, [characteristic.value hexadecimalStringWithDashes:YES]]];
        [self log:App message:[NSString stringWithFormat:@"\"%@\" received", [characteristic.value string]]];
    }
}

@end
