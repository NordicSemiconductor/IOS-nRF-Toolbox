//
//  DFUOperationsDetails.m
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 02/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "DFUOperationsDetails.h"
#import "Utility.h"
#import "IntelHex2BinConverter.h"

@implementation DFUOperationsDetails


-(void) enableNotification
{
    NSLog(@"DFUOperationsdetails enableNotification");
    [self.bluetoothPeripheral setNotifyValue:YES forCharacteristic:self.dfuControlPointCharacteristic];
}

-(void) startDFU:(DfuFirmwareTypes)firmwareType
{
    NSLog(@"DFUOperationsdetails startDFU");
    self.dfuFirmwareType = firmwareType;
    uint8_t value[] = {START_DFU_REQUEST, firmwareType};
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:2] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void)startOldDFU
{
    NSLog(@"DFUOperationsdetails startOldDFU");    
    uint8_t value[] = {START_DFU_REQUEST};
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:1] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) writeFileSize:(uint32_t)firmwareSize
{
    NSLog(@"DFUOperationsdetails writeFileSize");
    uint32_t fileSizeCollection[3];
    switch (self.dfuFirmwareType) {
        case SOFTDEVICE:
            fileSizeCollection[0] = firmwareSize;
            fileSizeCollection[1] = 0;
            fileSizeCollection[2] = 0;
            break;
        case BOOTLOADER:
            fileSizeCollection[0] = 0;
            fileSizeCollection[1] = firmwareSize;
            fileSizeCollection[2] = 0;
            break;
        case APPLICATION:
            fileSizeCollection[0] = 0;
            fileSizeCollection[1] = 0;
            fileSizeCollection[2] = firmwareSize;
            break;
            
        default:
            break;
    }    
    
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&fileSizeCollection length:12] forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];    
}

-(void) writeFilesSizes:(uint32_t)softdeviceSize bootloaderSize:(uint32_t)bootloaderSize
{
    NSLog(@"DFUOperationsdetails writeFilesSizes");
    uint32_t fileSizeCollection[3];
    fileSizeCollection[0] = softdeviceSize;
    fileSizeCollection[1] = bootloaderSize;
    fileSizeCollection[2] = 0;
        
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&fileSizeCollection length:12] forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];    
}

-(void) writeFileSizeForOldDFU:(uint32_t)firmwareSize
{
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&firmwareSize length:sizeof(firmwareSize)] forCharacteristic:self.dfuPacketCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

-(void) enablePacketNotification
{
    NSLog(@"DFUOperationsdetails enablePacketNotification");
    UInt8 value[3] = {PACKET_RECEIPT_NOTIFICATION_REQUEST, PACKETS_NOTIFICATION_INTERVAL,0};
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:3] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}


-(void) receiveFirmwareImage
{
    NSLog(@"DFUOperationsdetails receiveFirmwareImage");
    uint8_t value = RECEIVE_FIRMWARE_IMAGE_REQUEST;
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:1] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) validateFirmware
{
    NSLog(@"DFUOperationsdetails validateFirmwareImage");
    uint8_t value = VALIDATE_FIRMWARE_REQUEST;
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:1] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) activateAndReset
{
    NSLog(@"DFUOperationsdetails activateAndReset");
    uint8_t value = ACTIVATE_AND_RESET_REQUEST;
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:1] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) resetSystem
{
    NSLog(@"DFUOperationsDetails resetSystem");
    uint8_t value = RESET_SYSTEM;
    [self.bluetoothPeripheral writeValue:[NSData dataWithBytes:&value length:1] forCharacteristic:self.dfuControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) setPeripheralAndOtherParameters:(CBPeripheral *)peripheral controlPointCharacteristic:(CBCharacteristic *)controlPointCharacteristic packetCharacteristic:(CBCharacteristic *)packetCharacteristic
{
    NSLog(@"setPeripheralAndOtherParameters %@",peripheral.name);
    self.bluetoothPeripheral = peripheral;
    self.dfuControlPointCharacteristic = controlPointCharacteristic;
    self.dfuPacketCharacteristic = packetCharacteristic;
}

@end
