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
    DEVICE_NOT_SUPPORTED,
} DFUTargetResponse;

@protocol DFUTargetAdapterDelegate <NSObject>
/*!
 * @brief Called when service and characteristic discovery has finished.
 */
- (void) didFinishDiscovery;
/*!
 * @brief Called when service and characteristic discovery has finished but the required service or characteristics were not found.
 */
- (void) didFinishDiscoveryWithError;
/*!
 * @brief Invoked when Control Point characteristic has been written and confirmation has been received from peripheral.
 */
- (void) didWriteControlPoint;
/*!
 * @brief Invoked when all data packets before notification were send. Number of data packets before notification receipt may be set in application settings.
 */
- (void) didWriteDataPacket;
/*!
 * @brief Called when a response has been received from the peripheral. For data receipt see -(void)didReceiveReceipt method.
 */
- (void) didReceiveResponse:(DFUTargetResponse) response forCommand:(DFUTargetOpcode) opcode;
/*!
 * @brief Called when a data receipt has been received. The peripheral is now ready for more data packets.
 */
- (void) didReceiveReceipt;
@end

@interface DFUTargetAdapter : NSObject <CBPeripheralDelegate>
@property (nonatomic) CBPeripheral *peripheral;

+ (CBUUID *) serviceUUID;

- (DFUTargetAdapter *) initWithDelegate:(id<DFUTargetAdapterDelegate>) delegate;
- (void) startDiscovery;
- (void) sendNotificationRequest:(uint16_t) interval;
- (void) sendStartCommand:(int) firmwareLength;
- (void) sendReceiveCommand;
- (void) sendFirmwareData:(NSData *) data;
- (void) sendValidateCommand;
- (void) sendResetAndActivate:(BOOL)activate;
@end
