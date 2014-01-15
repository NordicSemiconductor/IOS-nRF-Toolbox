//
//  TargetController.h
//  nRF Loader
//
//  Created by Ole Morten on 10/8/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum
{
    START_DFU = 1,
    INITIALIZE_DFU_PARAMS,
    RECEIVE_FIRMWARE_IMAGE,
    VALIDATE_FIRMWARE,
    ACTIVATE_RESET,
    RESET,
    REPORT_SIZE,
    REQUEST_RECEIPT,
    RESPONSE_CODE = 0x10,
    RECEIPT,
} DFUTargetOpcode;

typedef enum
{
    SUCCESS = 0x01,
    INVALID_STATE,
    NOT_SUPPORTED,
    DATA_SIZE_EXCEEDS_LIMIT,
    CRC_ERROR,
    OPERATION_FAILED,
} DFUTargetResponse;

@protocol DFUTargetAdapterDelegate <NSObject>
- (void) didFinishDiscovery;
- (void) didWriteControlPoint;
- (void) didWriteDataPacket;
- (void) didReceiveResponse:(DFUTargetResponse) response forCommand:(DFUTargetOpcode) opcode;
- (void) didReceiveReceipt;
@end

@interface DFUTargetAdapter : NSObject <CBPeripheralDelegate>
@property (nonatomic) CBPeripheral *peripheral;

+ (CBUUID *) serviceUUID;

- (DFUTargetAdapter *) initWithDelegate:(id<DFUTargetAdapterDelegate>) delegate;
- (void) startDiscovery;
- (void) sendNotificationRequest:(int) interval;
- (void) sendStartCommand:(int) firmwareLength;
- (void) sendReceiveCommand;
- (void) sendFirmwareData:(NSData *) data;
- (void) sendValidateCommand;
- (void) sendResetAndActivate:(BOOL)activate;
@end
