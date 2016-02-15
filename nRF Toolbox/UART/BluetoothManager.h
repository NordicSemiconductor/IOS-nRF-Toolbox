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
#import "Logger.h"

@protocol BluetoothManagerDelegate

/*!
 * A callback called when the peripheral has been successfully connected.
 */
-(void)didDeviceConnected:(NSString *)peripheralName;
/*!
 * A callback called when the device got disconnected wither by user or due to a link loss.
 */
-(void)didDeviceDisconnected;
/*!
 * Method called when the device has been initialized and is ready to be used.
 */
-(void)isDeviceReady;
/*!
 * Method called when the device does not have the required service.
 */
-(void)deviceNotSupported;

@end

@interface BluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

-(instancetype)initWithManager:(CBCentralManager*)manager;

// Delegate properties
@property (nonatomic, weak) id<BluetoothManagerDelegate> delegate;
@property (nonatomic, weak) id<Logger> logger;

-(void)connectDevice:(CBPeripheral *)peripheral;
-(void)disconnectDevice;
-(void)send:(NSString *)text;
-(BOOL)isConnected;

@end
