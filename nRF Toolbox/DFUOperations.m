//
//  DFUOperations.m
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 18/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "DFUOperations.h"
#import "Utility.h"
#import "IntelHex2BinConverter.h"
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

bool isStartingSecondFile, isPerformedOldDFU;
NSDate *startTime, *finishTime;
double const delayInSeconds = 10.0;

-(DFUOperations *) initWithDelegate:(id<DFUOperationsDelegate>) delegate
{
    if (self = [super init])
    {
        dfuDelegate = delegate;
        dfuRequests = [[DFUOperationsDetails alloc]init];
        bleOperations = [[BLEOperations alloc]initWithDelegate:self];
        
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
    if (self.dfuFirmwareType == SOFTDEVICE || self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
        NSLog(@"waiting 10 seconds before sending file ...");
        //Delay of 10 seconds is required in order to update Softdevice in SDK 6.0
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [dfuRequests enablePacketNotification];
            [dfuRequests receiveFirmwareImage];
            [fileRequests writeNextPacket];
            [dfuDelegate onDFUStarted];
        });
    }
    else {
        [dfuRequests enablePacketNotification];
        [dfuRequests receiveFirmwareImage];
        [fileRequests writeNextPacket];
        [dfuDelegate onDFUStarted];
    }
    if (self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
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
            [self startSendingFile];
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

-(void)calculateDFUTime
{
    finishTime = [NSDate date];
    self.uploadTimeInSeconds = [finishTime timeIntervalSinceDate:startTime];
    NSLog(@"upload time in sec: %u",self.uploadTimeInSeconds);
}

#pragma mark - BLEOperations delegates

-(void)onDeviceConnected:(CBPeripheral *)peripheral withPacketCharacteristic:(CBCharacteristic *)dfuPacketCharacteristic andControlPointCharacteristic:(CBCharacteristic *)dfuControlPointCharacteristic
{
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
        isStartingSecondFile = YES;
        NSLog(@"Firmware type is Softdevice plus Bootloader. now upload bootloader ...");
        [dfuDelegate onSoftDeviceUploadCompleted];
        [dfuDelegate onBootloaderUploadStarted];
        [fileRequests2 writeNextPacket];
    }
}

-(void)onFileOpened:(NSUInteger)fileSizeOfBin
{
    NSLog(@"onFileOpened file size: %d",fileSizeOfBin);
    binFileSize += fileSizeOfBin;
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"DFUOperations: onError");
    [dfuDelegate onError:errorMessage];
}

@end

