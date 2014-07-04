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



@implementation DFUOperations

@synthesize dfuDelegate;
@synthesize centralManager;
@synthesize bluetoothPeripheral;
@synthesize dfuRequests;
//@synthesize binFileSize;
//@synthesize binFileSize2;
@synthesize firmwareFile;
@synthesize dfuResponse;
@synthesize fileRequests;
@synthesize fileRequests2;

bool isDFUPacketCharacteristicFound, isDFUControlPointCharacteristic, isStartingSecondFile;
double const delayInSeconds = 10.0;

-(DFUOperations *) initWithDelegate:(id<DFUOperationsDelegate>) delegate
{
    if (self = [super init])
    {
        dfuDelegate = delegate;
        dfuRequests = [[DFUOperationsDetails alloc]init];
    }
    return self;
}


-(void)setCentralManager:(CBCentralManager *)manager
{
    if (manager) {
        centralManager = manager;
        centralManager.delegate = self;
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
        bluetoothPeripheral = peripheral;
        bluetoothPeripheral.delegate = self;
        [centralManager connectPeripheral:peripheral options:nil];
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
    [self initFileOperations];
    [self initFileOperations2];
    isStartingSecondFile = NO;
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:softdeviceURL];
    [fileRequests2 openFile:bootloaderURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFilesSizes:(uint32_t)fileRequests.binFileSize bootloaderSize:(uint32_t)fileRequests2.binFileSize];
}

-(void)performDFUOnFile:(NSURL *)firmwareURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    [self initFileOperations];
    isStartingSecondFile = NO;
    firmwareFile = firmwareURL;
    self.dfuFirmwareType = firmwareType;
    [fileRequests openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFileSize:(uint32_t)fileRequests.binFileSize];
}

-(void)performOldDFUOnFile:(NSURL *)firmwareURL
{
    [self initFileOperations];
    isStartingSecondFile = NO;
    [fileRequests openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startOldDFU];
    [dfuRequests writeFileSize:(uint32_t)fileRequests.binFileSize];
}

-(void)initFileOperations
{
    fileRequests = [[FileOperations alloc]initWithDelegate:self
                                             blePeripheral:bluetoothPeripheral
                                         bleCharacteristic:self.dfuPacketCharacteristic];
}

-(void)initFileOperations2
{
    fileRequests2 = [[FileOperations alloc]initWithDelegate:self
                                             blePeripheral:bluetoothPeripheral
                                         bleCharacteristic:self.dfuPacketCharacteristic];
}

-(void) startSendingFile
{
    if (self.dfuFirmwareType == SOFTDEVICE || self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
        NSLog(@"waiting 10 seconds before sending file ...");
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
            NSLog(@"device has old DFU. switching to old DFU ...");
            [self performOldDFUOnFile:firmwareFile];
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

-(void)searchDFURequiredCharacteristics:(CBService *)service
{
    isDFUControlPointCharacteristic = NO;
    isDFUPacketCharacteristicFound = NO;
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Found characteristic %@",characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuControlPointCharacteristicUUIDString]]) {
            NSLog(@"Control Point characteristic found");
            isDFUControlPointCharacteristic = YES;
            self.dfuControlPointCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:dfuPacketCharacteristicUUIDString]]) {
            NSLog(@"Packet Characteristic is found");
            isDFUPacketCharacteristicFound = YES;
            self.dfuPacketCharacteristic = characteristic;
        }
    }
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

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"DFUOperations: onError");
    [dfuDelegate onError:errorMessage];
}

#pragma mark - CentralManager delegates
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    [bluetoothPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral");
    [dfuDelegate onDeviceDisconnected:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
    [dfuDelegate onDeviceDisconnected:peripheral];
}

#pragma mark - CBPeripheral delegates

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    for (CBService *service in peripheral.services) {
        NSLog(@"discovered service %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:dfuServiceUUIDString]]) {
            NSLog(@"DFU Service is found");
            [bluetoothPeripheral discoverCharacteristics:nil forService:service];
            return;
        }
    }
    NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering service\n Message: Required DFU service not available on peripheral"];
    [dfuDelegate onError:errorMessage];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService");
    [self searchDFURequiredCharacteristics:service];
    if (isDFUControlPointCharacteristic && isDFUPacketCharacteristicFound) {
        [dfuRequests setPeripheralAndOtherParameters:bluetoothPeripheral
                          controlPointCharacteristic:self.dfuControlPointCharacteristic
                                packetCharacteristic:self.dfuPacketCharacteristic];
        [dfuDelegate onDeviceConnected:bluetoothPeripheral];
    }
    else {
        NSString *errorMessage = [NSString stringWithFormat:@"Error on discovering characteristics\n Message: Required DFU characteristics are not available on peripheral"];
        [dfuDelegate onError:errorMessage];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic");
    if (error) {
        NSLog(@"Error in Notification state: %@",[error localizedDescription]);
    }
    else {
        NSLog(@"received notification %@",characteristic.value);
        [self processDFUResponse:(uint8_t *)[characteristic.value bytes]];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"error in writing characteristic %@ and error %@",characteristic.UUID,[error localizedDescription]);
        /*NSString *errorMessage = [NSString stringWithFormat:@"Error on Writing Characteristic %@\n Message: %@",characteristic.UUID,[error localizedDescription]];
        [dfuDelegate onError:errorMessage];*/

    }
    else {
        NSLog(@"didWriteValueForCharacteristic %@ and value %@",characteristic.UUID,characteristic.value);
    }
}


@end

