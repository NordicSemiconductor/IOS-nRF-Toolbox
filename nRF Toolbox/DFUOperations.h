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
#import "DFUOperationsDetails.h"
#import "Utility.h"
#import "FileOperations.h"
#import "BLEOperations.h"


@class DFUOperations;

//define protocol for the delegate
@protocol DFUOperationsDelegate

//define protocol functions that can be used in any class using this delegate
-(void)onDeviceConnected:(CBPeripheral *)peripheral;
-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral;
-(void)onDeviceDisconnected:(CBPeripheral *)peripheral;
-(void)onReadDFUVersion:(int)version;
-(void)onDFUStarted;
-(void)onDFUCancelled;
-(void)onSoftDeviceUploadStarted;
-(void)onBootloaderUploadStarted;
-(void)onSoftDeviceUploadCompleted;
-(void)onBootloaderUploadCompleted;
-(void)onTransferPercentage:(int)percentage;
-(void)onSuccessfulFileTranferred;
-(void)onError:(NSString *)errorMessage;

@end

@interface DFUOperations : NSObject <BLEOperationsDelegate, FileOperationsDelegate>

@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;
@property (strong, nonatomic)CBCharacteristic *dfuPacketCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuControlPointCharacteristic;
@property (strong, nonatomic)CBCharacteristic *dfuVersionCharacteristic;

@property (strong, nonatomic)BLEOperations *bleOperations;
@property (strong, nonatomic)DFUOperationsDetails *dfuRequests;
@property (strong, nonatomic)FileOperations *fileRequests;
@property (strong, nonatomic)FileOperations *fileRequests2;
@property (nonatomic)DfuFirmwareTypes dfuFirmwareType;
@property (nonatomic)NSUInteger binFileSize;
@property (nonatomic)NSUInteger uploadTimeInSeconds;
@property (strong, nonatomic)NSURL *firmwareFile;
@property (strong, nonatomic)NSURL *firmwareFileMetaData;

@property struct DFUResponse dfuResponse;

-(DFUOperations *) initWithDelegate:(id<DFUOperationsDelegate>) delegate;

//define delegate property
@property (nonatomic, assign)id<DFUOperationsDelegate> dfuDelegate;

//define public methods
-(void)setCentralManager:(CBCentralManager *)manager;
-(void)connectDevice:(CBPeripheral *)peripheral;
-(void)performDFUOnFile:(NSURL *)firmwareURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performDFUOnFileWithMetaData:(NSURL *)firmwareURL firmwareMetaDataURL:(NSURL *)metaDataURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performDFUOnFiles:(NSURL *)softdeviceURL bootloaderURL:(NSURL *)bootloaderURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performDFUOnFilesWithMetaData:(NSURL *)softdeviceURL bootloaderURL:(NSURL *)bootloaderURL firmwaresMetaDataURL:(NSURL *)metaDataURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performDFUOnFileWithMetaDataAndFileSizes:(NSURL *)firmwareURL firmwareMetaDataURL:(NSURL *)metaDataURL softdeviceFileSize:(uint32_t)softdeviceSize bootloaderFileSize:(uint32_t)bootloaderSize  firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performOldDFUOnFile:(NSURL *)firmwareURL;
-(void)setAppToBootloaderMode;
-(void)cancelDFU;

@end
