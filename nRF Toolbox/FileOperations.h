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

//define class for delegate FileOperationsDelegate
@class FileOperations;

//define protocol for the delegate
@protocol FileOperationsDelegate

//define protocol functions that will be implemented by the class that assign its id to fileDelegate
-(void)onTransferPercentage:(int)percentage;
-(void)onAllPacketsTranferred;
-(void)onFileOpened:(NSUInteger)fileSizeOfBin;
-(void)onError:(NSString *)errorMessage;


@end

@interface FileOperations : NSObject

//define properties
@property (nonatomic)NSUInteger binFileSize;
@property (strong, nonatomic)NSData *binFileData;
@property (nonatomic)int numberOfPackets;
@property (nonatomic)int bytesInLastPacket;
@property (nonatomic)int writingPacketNumber;
@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;
@property (strong, nonatomic)CBCharacteristic *dfuPacketCharacteristic;

//custom class initializer
-(FileOperations *) initWithDelegate:(id<FileOperationsDelegate>) delegate blePeripheral:(CBPeripheral *)peripheral bleCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic;

//define methods
-(void)openFile:(NSURL *)fileURL;
-(void)writeNextPacket;
-(void)setBLEParameters:(CBPeripheral *)peripheral bleCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic;

//define delegate property
@property (nonatomic, assign)id<FileOperationsDelegate> fileDelegate;

@end
