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

#import "DFUOperations.h"
#import "Utility.h"
#import "DFUOperationsDetails.h"
#import "BLEOperations.h"



@implementation DFUOperations

@synthesize dfuDelegate;
@synthesize dfuRequests;
@synthesize binFileSize;
@synthesize firmwareFile;
@synthesize dfuResponse;
@synthesize fileRequests;
@synthesize fileRequests2;
@synthesize bleOperations;

bool isStartingSecondFile, isPerformedOldDFU, isVersionCharacteristicExist, isOneFileForSDAndBL;
NSDate *startTime, *finishTime;



-(DFUOperations *) initWithDelegate:(id<DFUOperationsDelegate>) delegate
{
    if (self = [super init])
    {
        dfuDelegate = delegate;
        dfuRequests = [[DFUOperationsDetails alloc]init];
        bleOperations = [[BLEOperations alloc]initWithDelegate:self];
        isOneFileForSDAndBL = NO;
    }
    return self;
}


-(void)setCentralManager:(CBCentralManager *)manager
{
    if (manager) {
        [bleOperations setBluetoothCentralManager:manager];
    }
    else {
        NSLog(@"CBCentralManager is nil");
        NSString *errorMessage = [NSString stringWithFormat:@"Error on received CBCentralManager\n Message: Bluetooth central manager is nil"];
        [dfuDelegate onError:errorMessage];
    }
}

-(void)connectDevice:(CBPeripheral *)peripheral
{
    if (peripheral) {
        [bleOperations connectDevice:peripheral];
    }
    else {
        NSLog(@"CBPeripheral is nil");
        NSString *errorMessage = [NSString stringWithFormat:@"Error on received CBPeripheral\n Message: Bluetooth peripheral is nil"];
        [dfuDelegate onError:errorMessage];
    }
}

-(void)cancelDFU
{
    NSLog(@"cancelDFU");
    [dfuRequests resetSystem];
    [dfuDelegate onDFUCancelled];
}

-(void)setAppToBootloaderMode
{
    NSLog(@"setAppToBootloaderMode");
    [dfuRequests resetAppToDFUMode];    
}

-(void)performDFUOnFiles:(NSURL *)softdeviceURL bootloaderURL:(NSURL *)bootloaderURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    isPerformedOldDFU = NO;
    [self initFirstFileOperations];
    [self initSecondFileOperations];
    [self initParameters];
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:softdeviceURL];
    [fileRequests2 openFile:bootloaderURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFilesSizes:(uint32_t)fileRequests.binFileSize bootloaderSize:(uint32_t)fileRequests2.binFileSize];
}

-(void)performDFUOnFilesWithMetaData:(NSURL *)softdeviceURL bootloaderURL:(NSURL *)bootloaderURL firmwaresMetaDataURL:(NSURL *)metaDataURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    self.firmwareFileMetaData = metaDataURL;
    isOneFileForSDAndBL = NO;
    isPerformedOldDFU = NO;
    [self initFirstFileOperations];
    [self initSecondFileOperations];
    [self initParameters];
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:softdeviceURL];
    [fileRequests2 openFile:bootloaderURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFilesSizes:(uint32_t)fileRequests.binFileSize bootloaderSize:(uint32_t)fileRequests2.binFileSize];
    if (isVersionCharacteristicExist) {
        [dfuRequests getDfuVersion];
    }
}

-(void)performDFUOnFileWithMetaDataAndFileSizes:(NSURL *)firmwareURL firmwareMetaDataURL:(NSURL *)metaDataURL softdeviceFileSize:(uint32_t)softdeviceSize bootloaderFileSize:(uint32_t)bootloaderSize  firmwareType:(DfuFirmwareTypes)firmwareType
{
    self.firmwareFileMetaData = metaDataURL;
    isOneFileForSDAndBL = YES;
    isPerformedOldDFU = NO;
    firmwareFile = firmwareURL;
    [self initFirstFileOperations];
    isStartingSecondFile = NO;
    [self initParameters];
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFilesSizes:(uint32_t)softdeviceSize bootloaderSize:(uint32_t)bootloaderSize];
    if (isVersionCharacteristicExist) {
        [dfuRequests getDfuVersion];
    }
}


-(void)performDFUOnFile:(NSURL *)firmwareURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    isPerformedOldDFU = NO;
    firmwareFile = firmwareURL;
    [self initFirstFileOperations];
    isStartingSecondFile = NO;
    [self initParameters];
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFileSize:(uint32_t)fileRequests.binFileSize];
    if (isVersionCharacteristicExist) {
        [dfuRequests getDfuVersion];
    }
}

-(void)performDFUOnFileWithMetaData:(NSURL *)firmwareURL firmwareMetaDataURL:(NSURL *)metaDataURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    self.firmwareFileMetaData = metaDataURL;
    isPerformedOldDFU = NO;
    firmwareFile = firmwareURL;
    [self initFirstFileOperations];
    isStartingSecondFile = NO;
    [self initParameters];
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFileSize:(uint32_t)fileRequests.binFileSize];
    if (isVersionCharacteristicExist) {
        [dfuRequests getDfuVersion];
    }
}

-(void)performOldDFUOnFile:(NSURL *)firmwareURL
{
    isPerformedOldDFU = YES;
    if (firmwareURL && self.dfuFirmwareType == APPLICATION) {
        [self initFirstFileOperations];
        [self initParameters];
        [fileRequests openFile:firmwareURL];
        [dfuRequests enableNotification];
        [dfuRequests startOldDFU];
        [dfuRequests writeFileSizeForOldDFU:(uint32_t)fileRequests.binFileSize];
    }
    else {
        NSString *errorMessage = [NSString stringWithFormat:@"Old DFU only supports Application upload"];
        [dfuDelegate onError:errorMessage];
        [dfuRequests resetSystem];
    }
    
}

-(void)initParameters
{
    startTime = [NSDate date];
    binFileSize = 0;
    isStartingSecondFile = NO;
}

-(void)initFirstFileOperations
{
    fileRequests = [[FileOperations alloc]initWithDelegate:self
                                             blePeripheral:self.bluetoothPeripheral
                                         bleCharacteristic:self.dfuPacketCharacteristic];
}

-(void)initSecondFileOperations
{
    fileRequests2 = [[FileOperations alloc]initWithDelegate:self
                                             blePeripheral:self.bluetoothPeripheral
                                         bleCharacteristic:self.dfuPacketCharacteristic];
}

-(void) startSendingFile
{
    [dfuRequests enablePacketNotification];
    [dfuRequests receiveFirmwareImage];
    [fileRequests writeNextPacket];
    [dfuDelegate onDFUStarted];
    if (self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER && !isOneFileForSDAndBL) {
        [dfuDelegate onSoftDeviceUploadStarted];
    }
}

-(NSString *) responseErrorMessage:(DfuOperationStatus)errorCode
{
    switch (errorCode) {
        case OPERATION_FAILED_RESPONSE:
            return @"Operation Failed";
            break;
        case OPERATION_INVALID_RESPONSE:
            return @"Invalid Response";
            break;
        case OPERATION_NOT_SUPPORTED_RESPONSE:
            return @"Operation Not Supported";
            break;
        case DATA_SIZE_EXCEEDS_LIMIT_RESPONSE:
            return @"Data Size Exceeds";
            break;
        case CRC_ERROR_RESPONSE:
            return @"CRC Error";
            break;
        default:
            return @"unknown Error";
            break;
    }
}

-(void)processRequestedCode
{
    NSLog(@"processsRequestedCode");
    switch (dfuResponse.requestedCode) {
        case START_DFU_REQUEST:
            NSLog(@"Requested code is StartDFU now processing response status");
            [self processStartDFUResponseStatus];
            break;
        case RECEIVE_FIRMWARE_IMAGE_REQUEST:
            NSLog(@"Requested code is Receive Firmware Image now processing response status");
            [self processReceiveFirmwareResponseStatus];
            break;
        case VALIDATE_FIRMWARE_REQUEST:
            NSLog(@"Requested code is Validate Firmware now processing response status");
            [self processValidateFirmwareResponseStatus];
            break;
        case INITIALIZE_DFU_PARAMETERS_REQUEST:
            NSLog(@"Requested code is Initialize DFU Parameters now processing response status");
            [self processInitPacketResponseStatus];
            break;
            
        default:
            NSLog(@"invalid Requested code in DFU Response %d",dfuResponse.requestedCode);
            break;
    }
}

-(void)processStartDFUResponseStatus
{
    NSLog(@"processStartDFUResponseStatus");
    NSString *errorMessage = [NSString stringWithFormat:@"Error on StartDFU\n Message: %@",[self responseErrorMessage:dfuResponse.responseStatus]];
    switch (dfuResponse.responseStatus) {
        case OPERATION_SUCCESSFUL_RESPONSE:
            NSLog(@"successfully received startDFU notification");
            //Start initPacket in order to support ned DFU in SDK 7.1
            if (isVersionCharacteristicExist) {
                [dfuRequests sendInitPacket:self.firmwareFileMetaData];
            }
            else {
                [self startSendingFile];
            }
            break;
        case OPERATION_NOT_SUPPORTED_RESPONSE:
            if (!isPerformedOldDFU) {
                NSLog(@"device has old DFU. switching to old DFU ...");
                [self performOldDFUOnFile:firmwareFile];
            }
            else {
                NSLog(@"Operation not supported");
                NSLog(@"Firmware Image failed, Error Status: %@",[self responseErrorMessage:dfuResponse.responseStatus]);
                NSString *errorMessage = [NSString stringWithFormat:@"Error on StartDFU\n Message: %@",[self responseErrorMessage:dfuResponse.responseStatus]];
                [dfuDelegate onError:errorMessage];
                [dfuRequests resetSystem];
            }
            break;
            
        default:
            NSLog(@"StartDFU failed, Error Status: %@",[self responseErrorMessage:dfuResponse.responseStatus]);
            [dfuDelegate onError:errorMessage];
            [dfuRequests resetSystem];
            break;
    }
}

-(void)processInitPacketResponseStatus
{
    NSLog(@"processInitPacketResponseStatus");
    if(dfuResponse.responseStatus == OPERATION_SUCCESSFUL_RESPONSE) {
        NSLog(@"successfully received initPacket notification");
        [self startSendingFile];
    }
    else {
        //NSLog(@"unsuccessfull initPacket notification %d",dfuResponse.responseStatus);
        NSLog(@"Init Packet failed, Error Status: %@",[self responseErrorMessage:dfuResponse.responseStatus]);
        NSString *errorMessage = [NSString stringWithFormat:@"Error on Init Packet\n Message: %@",[self responseErrorMessage:dfuResponse.responseStatus]];
        [dfuDelegate onError:errorMessage];
        [dfuRequests resetSystem];
    }
}

-(void)processReceiveFirmwareResponseStatus
{
    NSLog(@"processReceiveFirmwareResponseStatus");
    if (dfuResponse.responseStatus == OPERATION_SUCCESSFUL_RESPONSE) {
        NSLog(@"successfully received notification for whole File transfer");
        [dfuRequests validateFirmware];
    }
    else {
        NSLog(@"Firmware Image failed, Error Status: %@",[self responseErrorMessage:dfuResponse.responseStatus]);
        NSString *errorMessage = [NSString stringWithFormat:@"Error on Receive Firmware Image\n Message: %@",[self responseErrorMessage:dfuResponse.responseStatus]];
        [dfuDelegate onError:errorMessage];
        [dfuRequests resetSystem];
    }
}

-(void)processValidateFirmwareResponseStatus
{
    NSLog(@"processValidateFirmwareResponseStatus");
    if (dfuResponse.responseStatus == OPERATION_SUCCESSFUL_RESPONSE) {
        NSLog(@"succesfully received notification for ValidateFirmware");
        [dfuRequests activateAndReset];
        [self calculateDFUTime];
        [dfuDelegate onSuccessfulFileTranferred];
    }
    else {
        NSLog(@"Firmware validate failed, Error Status: %@",[self responseErrorMessage:dfuResponse.responseStatus]);
        NSString *errorMessage = [NSString stringWithFormat:@"Error on Validate Firmware Request\n Message: %@",[self responseErrorMessage:dfuResponse.responseStatus]];
        [dfuDelegate onError:errorMessage];
        [dfuRequests resetSystem];
    }
}

-(void)processPacketNotification
{
    NSLog(@"received Packet Received Notification");
    if (isStartingSecondFile) {
        if (fileRequests2.writingPacketNumber < fileRequests2.numberOfPackets) {
            [fileRequests2 writeNextPacket];
        }
    }
    else {
        if (fileRequests.writingPacketNumber < fileRequests.numberOfPackets) {
            [fileRequests writeNextPacket];
        }
    }
}

-(void)processDFUResponse:(uint8_t *)data
{
    NSLog(@"processDFUResponse");
    [self setDFUResponseStruct:data];
    if (dfuResponse.responseCode == RESPONSE_CODE) {
        [self processRequestedCode];
    }
    else if(dfuResponse.responseCode == PACKET_RECEIPT_NOTIFICATION_RESPONSE) {
        [self processPacketNotification];
    }
}

-(void)setDFUResponseStruct:(uint8_t *)data
{
    dfuResponse.responseCode = data[0];
    dfuResponse.requestedCode = data[1];
    dfuResponse.responseStatus = data[2];
}

-(void)setDFUOperationsDetails
{
    [self.dfuRequests setPeripheralAndOtherParameters:self.bluetoothPeripheral
                           controlPointCharacteristic:self.dfuControlPointCharacteristic
                                 packetCharacteristic:self.dfuPacketCharacteristic];
}

-(void)setDFUOperationsDetailsWithVersion
{
    [self.dfuRequests setPeripheralAndOtherParametersWithVersion:self.bluetoothPeripheral
                           controlPointCharacteristic:self.dfuControlPointCharacteristic
                                 packetCharacteristic:self.dfuPacketCharacteristic
                                versionCharacteristic:self.dfuVersionCharacteristic];
}

-(void)calculateDFUTime
{
    finishTime = [NSDate date];
    self.uploadTimeInSeconds = [finishTime timeIntervalSinceDate:startTime];
    NSLog(@"upload time in sec: %lu",(unsigned long)self.uploadTimeInSeconds);
}

#pragma mark - BLEOperations delegates

-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral
        withPacketCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic
        andControlPointCharacteristic:(CBCharacteristic *)dfuControlPointCharacteristic
        andVersionCharacteristic:(CBCharacteristic *)dfuVersionCharacteristic
{
    isVersionCharacteristicExist = YES;
    self.bluetoothPeripheral = peripheral;
    self.dfuPacketCharacteristic = dfuPacketCharacteristic;
    self.dfuControlPointCharacteristic = dfuControlPointCharacteristic;
    self.dfuVersionCharacteristic = dfuVersionCharacteristic;
    [self setDFUOperationsDetailsWithVersion];
    [dfuDelegate onDeviceConnectedWithVersion:peripheral];
}

-(void)onDeviceConnected:(CBPeripheral *)peripheral
withPacketCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic
andControlPointCharacteristic:(CBCharacteristic *)dfuControlPointCharacteristic
{
    isVersionCharacteristicExist = NO;
    self.bluetoothPeripheral = peripheral;
    self.dfuPacketCharacteristic = dfuPacketCharacteristic;
    self.dfuControlPointCharacteristic = dfuControlPointCharacteristic;
    [self setDFUOperationsDetails];
    [dfuDelegate onDeviceConnected:peripheral];
}


-(void)onDeviceDisconnected:(CBPeripheral *)peripheral
{
    [dfuDelegate onDeviceDisconnected:peripheral];
}

-(void)onReadDfuVersion:(int)version
{
    NSLog(@"onReadDfuVersion %d",version);
    //check if DfuVersionCharacteristic has been read successfully
    //one reason is that Service Changed Indication is not enabled in Buttonless DFU update
    if (version == 0) {
        [dfuRequests resetSystem];
    }
    else {
        [dfuDelegate onReadDFUVersion:version];
    }
}

-(void)onReceivedNotification:(NSData *)data
{
    [self processDFUResponse:(uint8_t *)[data bytes]];
}

#pragma mark - FileOperations delegates

-(void)onTransferPercentage:(int)percentage
{
    NSLog(@"DFUOperations: onTransferPercentage %d",percentage);
    [dfuDelegate onTransferPercentage:percentage];
}

-(void)onAllPacketsTranferred
{
    NSLog(@"DFUOperations: onAllPacketsTransfered");
    if (isStartingSecondFile) {
        [dfuDelegate onBootloaderUploadCompleted];
    }
    else if (self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
        //TODO test if there is one file with both softdevice and bootloader inside as given by manifest.json
        //if there are two files for softdevice and bootloader
        if (!isOneFileForSDAndBL) {
            isStartingSecondFile = YES;
            NSLog(@"Firmware type is Softdevice plus Bootloader. now upload bootloader ...");
            [dfuDelegate onSoftDeviceUploadCompleted];
            [dfuDelegate onBootloaderUploadStarted];
            [fileRequests2 writeNextPacket];
        }
        else { //if there is one file for both softdevice and bootloader as mentioned in manifest.json
            isOneFileForSDAndBL = NO;
        }
        
    }
}

-(void)onFileOpened:(NSUInteger)fileSizeOfBin
{
    NSLog(@"onFileOpened file size: %lu",(unsigned long)fileSizeOfBin);
    binFileSize += fileSizeOfBin;
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"DFUOperations: onError");
    [dfuDelegate onError:errorMessage];
}

@end

