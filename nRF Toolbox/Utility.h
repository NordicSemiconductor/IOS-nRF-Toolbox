//
//  Utility.h
//  nRFDeviceFirmwareUpdate
//
//  Created by Nordic Semiconductor on 22/05/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

extern NSString * const dfuServiceUUIDString;
extern NSString * const dfuControlPointCharacteristicUUIDString;
extern NSString * const dfuPacketCharacteristicUUIDString;

extern NSString* const FIRMWARE_TYPE_SOFTDEVICE;
extern NSString* const FIRMWARE_TYPE_BOOTLOADER;
extern NSString* const FIRMWARE_TYPE_APPLICATION;
extern NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER;


extern int PACKETS_NOTIFICATION_INTERVAL;
extern int const PACKET_SIZE;

struct DFUResponse
{
    uint8_t responseCode;
    uint8_t requestedCode;
    uint8_t responseStatus;
    
};

typedef enum {
    HEX,
    ZIP
}enumFileExtension;

typedef enum {
    START_DFU_REQUEST = 0x01,
    INITIALIZE_DFU_PARAMETERS_REQUEST = 0x02,
    RECEIVE_FIRMWARE_IMAGE_REQUEST = 0x03,
    VALIDATE_FIRMWARE_REQUEST = 0x04,
    ACTIVATE_AND_RESET_REQUEST = 0x05,
    RESET_SYSTEM = 0x06,
    PACKET_RECEIPT_NOTIFICATION_REQUEST = 0x08,
    RESPONSE_CODE = 0x10,
    PACKET_RECEIPT_NOTIFICATION_RESPONSE = 0x11
    
}DfuOperations;

typedef enum {
    OPERATION_SUCCESSFUL_RESPONSE = 0x01,
    OPERATION_INVALID_RESPONSE = 0x02,
    OPERATION_NOT_SUPPORTED_RESPONSE = 0x03,
    DATA_SIZE_EXCEEDS_LIMIT_RESPONSE = 0x04,
    CRC_ERROR_RESPONSE = 0x05,
    OPERATION_FAILED_RESPONSE = 0x06
    
}DfuOperationStatus;

typedef enum {    
    SOFTDEVICE = 0x01,
    BOOTLOADER = 0x02,
    SOFTDEVICE_AND_BOOTLOADER = 0x03,
    APPLICATION = 0x04    
    
}DfuFirmwareTypes;

+ (NSArray *) getFirmwareTypes;
+ (NSString *) stringFileExtension:(enumFileExtension)fileExtension;
+ (NSString *) getDFUHelpText;
+ (NSString *) getEmptyUserFilesText;
+ (NSString *) getDFUAppFileHelpText;
+ (void) showAlert:(NSString *)message;

@end
