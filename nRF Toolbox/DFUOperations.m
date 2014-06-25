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
@synthesize binFileSize;
@synthesize binFileSize2;
@synthesize firmwareFile;

bool isDFUPacketCharacteristicFound, isDFUControlPointCharacteristic, isStartingSecondFile;
int numberOfPackets, bytesInLastPacket, numberOfPackets2, bytesInLastPacket2;
int writingPacketNumber = 0;
int writingPacketNumber2 = 0;
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
    isStartingSecondFile = NO;
    self.dfuFirmwareType = firmwareType;
    [self openFile:softdeviceURL];
    [self openFile2:bootloaderURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFilesSizes:(uint32_t)self.binFileData.length bootloaderSize:(uint32_t)self.binFileData2.length];
}

-(void)performDFUOnFile:(NSURL *)firmwareURL firmwareType:(DfuFirmwareTypes)firmwareType
{
    isStartingSecondFile = NO;
    firmwareFile = firmwareURL;
    self.dfuFirmwareType = firmwareType;
    [self openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startDFU:firmwareType];
    [dfuRequests writeFileSize:(uint32_t)self.binFileData.length];
}

-(void)performOldDFUOnFile:(NSURL *)firmwareURL
{
    isStartingSecondFile = NO;
    [self openFile:firmwareURL];
    [dfuRequests enableNotification];
    [dfuRequests startOldDFU];
    [dfuRequests writeFileSizeForOldDFU:(uint32_t)self.binFileData.length];
}

-(void) openFile:(NSURL *)fileURL
{
    NSData *hexFileData = [NSData dataWithContentsOfURL:fileURL];
    if (hexFileData.length > 0) {
        self.binFileData = [IntelHex2BinConverter convert:hexFileData];
        NSLog(@"HexFileSize: %lu and BinFileSize: %lu",(unsigned long)hexFileData.length,(unsigned long)self.binFileData.length);
        numberOfPackets = ceil((double)self.binFileData.length / (double)PACKET_SIZE);
        bytesInLastPacket = (self.binFileData.length % PACKET_SIZE);
        if (bytesInLastPacket == 0) {
            bytesInLastPacket = PACKET_SIZE;
        }
        NSLog(@"Number of Packets %d Bytes in last Packet %d",numberOfPackets,bytesInLastPacket);
        writingPacketNumber = 0;        
        binFileSize = self.binFileData.length;
    }
    else {
        NSLog(@"Error: file is empty!");
        NSString *errorMessage = [NSString stringWithFormat:@"Error on openning file\n Message: file is empty or not exist"];
        [dfuDelegate onError:errorMessage];
    }
    
}

-(void) openFile2:(NSURL *)fileURL2
{
    NSData *hexFileData = [NSData dataWithContentsOfURL:fileURL2];
    self.binFileData2 = [IntelHex2BinConverter convert:hexFileData];
    NSLog(@"HexFileSize: %lu and BinFileSize2: %lu",(unsigned long)hexFileData.length,(unsigned long)self.binFileData2.length);
    numberOfPackets2 = ceil((double)self.binFileData2.length / (double)PACKET_SIZE);
    bytesInLastPacket2 = (self.binFileData2.length % PACKET_SIZE);
    if (bytesInLastPacket2 == 0) {
        bytesInLastPacket2 = PACKET_SIZE;
    }
    NSLog(@"Number of Packets %d Bytes in last Packet %d",numberOfPackets2,bytesInLastPacket2);
    writingPacketNumber2 = 0;
    binFileSize2 = self.binFileData2.length;
}

-(void) writeNextPacket
{
    int percentage = 0;
    for (int index = 0; index<PACKETS_NOTIFICATION_INTERVAL; index++) {
        if (writingPacketNumber > numberOfPackets-2) {
            NSLog(@"writing last packet");
            NSRange dataRange = NSMakeRange(writingPacketNumber*PACKET_SIZE, bytesInLastPacket);
            NSData *nextPacketData = [self.binFileData subdataWithRange:dataRange];
            NSLog(@"writing packet number %d ...",writingPacketNumber+1);
            [self.bluetoothPeripheral writeValue:nextPacketData forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];
            if (self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
                isStartingSecondFile = YES;
                NSLog(@"Firmware type is Softdevice plus Bootloader. now upload bootloader ...");
                [dfuDelegate onSoftDeviceUploadCompleted];
                [dfuDelegate onBootloaderUploadStarted];
                [self writeNextPacket2];
            }
            
            break;
        }
        NSRange dataRange = NSMakeRange(writingPacketNumber*PACKET_SIZE, PACKET_SIZE);
        NSData *nextPacketData = [self.binFileData subdataWithRange:dataRange];
        NSLog(@"writing packet number %d ...",writingPacketNumber+1);
        [self.bluetoothPeripheral writeValue:nextPacketData forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];
        percentage = (((double)(writingPacketNumber * 20) / (double)(binFileSize)) * 100);
        [dfuDelegate onTransferPercentage:percentage];
        writingPacketNumber++;
        
    }
}

-(void) writeNextPacket2
{
    int percentage = 0;
    for (int index = 0; index<PACKETS_NOTIFICATION_INTERVAL; index++) {
        if (writingPacketNumber2 > numberOfPackets2-2) {
            NSLog(@"writing last packet");
            NSRange dataRange = NSMakeRange(writingPacketNumber2*PACKET_SIZE, bytesInLastPacket2);
            NSData *nextPacketData = [self.binFileData2 subdataWithRange:dataRange];
            NSLog(@"writing packet number %d ...",writingPacketNumber2+1);
            [self.bluetoothPeripheral writeValue:nextPacketData forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];
            [dfuDelegate onBootloaderUploadCompleted];
            break;
        }
        NSRange dataRange = NSMakeRange(writingPacketNumber2*PACKET_SIZE, PACKET_SIZE);
        NSData *nextPacketData = [self.binFileData2 subdataWithRange:dataRange];
        NSLog(@"writing packet number %d ...",writingPacketNumber2+1);
        [self.bluetoothPeripheral writeValue:nextPacketData forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];
        percentage = (((double)(writingPacketNumber2 * 20) / (double)(binFileSize2)) * 100);
        [dfuDelegate onTransferPercentage:percentage];
        writingPacketNumber2++;
        
    }
}

-(void) startSendingFile
{
    if (self.dfuFirmwareType == SOFTDEVICE || self.dfuFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
        NSLog(@"waiting 10 seconds before sending file ...");
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [dfuRequests enablePacketNotification];
            [dfuRequests receiveFirmwareImage];
            [self writeNextPacket];
            [dfuDelegate onDFUStarted];
        });
    }
    else {
        [dfuRequests enablePacketNotification];
        [dfuRequests receiveFirmwareImage];
        [self writeNextPacket];
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
        uint8_t *data = (uint8_t *)[characteristic.value bytes];
        if (data[0] == RESPONSE_CODE && data[1] == START_DFU_REQUEST) {
            if (data[2] == OPERATION_SUCCESSFUL_RESPONSE) {
                NSLog(@"successfully received startDFU notification %@",characteristic.value);
                [self startSendingFile];
            }
            else {
                NSLog(@"Start DFU failed, Error Status: %@",[self responseErrorMessage:data[2]]);
                if ([[self responseErrorMessage:data[2]] isEqual:@"Operation Not Supported"]) {
                    NSLog(@"device has old DFU. switching to old DFU ...");
                    [self performOldDFUOnFile:firmwareFile];
                }
                else {
                    NSString *errorMessage = [NSString stringWithFormat:@"Error on StartDFU\n Message: %@",[self responseErrorMessage:data[2]]];
                    [dfuDelegate onError:errorMessage];
                    [dfuRequests resetSystem];
                }
            }
        }
        else if (data[0] == PACKET_RECEIPT_NOTIFICATION_RESPONSE) {
            NSLog(@"received Packet Received Notification %@",characteristic.value);
            if (isStartingSecondFile) {
                [self writeNextPacket2];
            }
            else {
                [self writeNextPacket];
            }
        }
        else if (data[0] == RESPONSE_CODE && data[1] == RECEIVE_FIRMWARE_IMAGE_REQUEST) {
            if (data[2] == OPERATION_SUCCESSFUL_RESPONSE) {
                NSLog(@"successfully received notification for whole File transfer");
                [dfuRequests validateFirmware];
            }
            else {
                NSLog(@"Receive Firmware Image failed, Error Status: %@",[self responseErrorMessage:data[2]]);
                NSString *errorMessage = [NSString stringWithFormat:@"Error on Receive Firmware Image\n Message: %@",[self responseErrorMessage:data[2]]];
                [dfuDelegate onError:errorMessage];

            }
        }
        else if (data[0] == RESPONSE_CODE && data[1] == VALIDATE_FIRMWARE_REQUEST) {
            if (data[2] == OPERATION_SUCCESSFUL_RESPONSE) {
                NSLog(@"succesfully received notification for ValidateFirmware");
                [dfuRequests activateAndReset];
                [dfuDelegate onSuccessfulFileTranferred];
                
            }
            else {
                NSLog(@"Firmware validate failed, Error Status: %@",[self responseErrorMessage:data[2]]);
                NSString *errorMessage = [NSString stringWithFormat:@"Error on Validate Firmware Request\n Message: %@",[self responseErrorMessage:data[2]]];
                [dfuDelegate onError:errorMessage];
            }
        }
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

