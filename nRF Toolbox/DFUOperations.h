//
//  DFUOperations.h
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 18/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

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
-(void)onDeviceDisconnected:(CBPeripheral *)peripheral;
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

@property (strong, nonatomic)BLEOperations *bleOperations;
@property (strong, nonatomic)DFUOperationsDetails *dfuRequests;
@property (strong, nonatomic)FileOperations *fileRequests;
@property (strong, nonatomic)FileOperations *fileRequests2;
@property (nonatomic)DfuFirmwareTypes dfuFirmwareType;
@property (nonatomic)NSUInteger binFileSize;
@property (nonatomic)NSUInteger uploadTimeInSeconds;
@property (strong, nonatomic)NSURL *firmwareFile;
@property struct DFUResponse dfuResponse;

-(DFUOperations *) initWithDelegate:(id<DFUOperationsDelegate>) delegate;

//define delegate property
@property (nonatomic, assign)id<DFUOperationsDelegate> dfuDelegate;

//define public methods
-(void)setCentralManager:(CBCentralManager *)manager;
-(void)connectDevice:(CBPeripheral *)peripheral;
-(void)performDFUOnFile:(NSURL *)firmwareURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performDFUOnFiles:(NSURL *)softdeviceURL bootloaderURL:(NSURL *)bootloaderURL firmwareType:(DfuFirmwareTypes)firmwareType;
-(void)performOldDFUOnFile:(NSURL *)firmwareURL;

-(void)cancelDFU;

@end
