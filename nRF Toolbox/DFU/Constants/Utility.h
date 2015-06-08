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

@interface Utility : NSObject

extern NSString * const dfuServiceUUIDString;
extern NSString * const dfuControlPointCharacteristicUUIDString;
extern NSString * const dfuPacketCharacteristicUUIDString;
extern NSString * const dfuVersionCharacteritsicUUIDString;

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
    BIN,
    ZIP
}enumFileExtension;

typedef enum {
    START_INIT_PACKET = 0x00,
    END_INIT_PACKET = 0x01
}initPacketParam;

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
+ (NSString *) getEmptyFolderText;
+ (NSString *) getDFUAppFileHelpText;
+ (void) showAlert:(NSString *)message;
+(void)showBackgroundNotification:(NSString *)message;
+ (BOOL)isApplicationStateInactiveORBackground;

@end
