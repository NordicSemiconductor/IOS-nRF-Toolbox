//
//  FileOperations.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 03/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

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
