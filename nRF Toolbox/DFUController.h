//
//  DFUControllerStateMachine.h
//  nRF Loader
//
//  Created by Ole Morten on 10/22/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFUTargetAdapter.h"

typedef enum
{
    INIT,
    DISCOVERING,
    IDLE,
    SEND_NOTIFICATION_REQUEST,
    SEND_START_COMMAND,
    SEND_RECEIVE_COMMAND,
    SEND_FIRMWARE_DATA,
    SEND_VALIDATE_COMMAND,
    SEND_RESET,
    WAIT_RECEIPT,
    FINISHED,
    CANCELED,
    ERROR,
} DFUControllerState;


@protocol DFUControllerDelegate <NSObject>
/*!
 * @brief Invoked when the DFU controller has changed its state.
 * @param state the new state of the controller
 */
- (void) didChangeState:(DFUControllerState) state;
/*!
 * @brief Called when upload progress has changed. This method is invoked after each packet has been added to sending queue, it does not mean that it was really transmitted.
 *        As the Central Manager is created with custom event queue (see ScannerViewController.m -> viewDidLoad)
 *        this method must dispatch asynch request to the main queue in order to update UI.
 * @param progress the current progress, float value from 0 to 1 where 1 means that the last byte has been added to the queue
 */
- (void) didUpdateProgress:(float) progress;
/*!
 * @brief Invoked when the DFU process has been completed and the RESET AND ACTIVATE commang has been send to the peripheral.
 *        As the Central Manager is created with custom event queue (see ScannerViewController.m -> viewDidLoad)
 *        this method must dispatch asynch request to the main queue in order to update UI.
 */
- (void) didFinishTransfer;
/*!
 * @brief Called just after invoking cancelTransfer. The RESET command will be send just after it.
 *        As the Central Manager is created with custom event queue (see ScannerViewController.m -> viewDidLoad)
 *        this method must dispatch asynch request to the main queue in order to update UI.
 */
- (void) didCancelTransfer;
/*!
 * Invoked when the response recieved to Control Point characteristic is other than SUCCESS.
 * @param error the status returned from the peripheral
 */
- (void) didErrorOccurred:(DFUTargetResponse) error;
/*!
 * @brief Called when the connection has been terminated unless the firmware transfer was finished, cancelled of has failed. In
 *        The three later cases the (void)didFinishedTransfer, (void)didCancelTransfer, (void)didErrorOccurred:(DFUTargetResponse)error will be called.
 */
- (void) didDisconnect:(NSError *) error;
@end

@interface DFUController : NSObject <DFUTargetAdapterDelegate>
@property (strong, nonatomic) id<DFUControllerDelegate> delegate;

@property (copy, nonatomic) NSString *appName;
@property (assign, nonatomic) unsigned long appSize;
@property (readonly, nonatomic) unsigned long binSize;
@property (readonly, nonatomic) NSTimeInterval uploadInterval;

@property (copy, nonatomic) NSString *targetName;

+ (CBUUID *) serviceUUID;

- (DFUController *) initWithDelegate:(id<DFUControllerDelegate>) delegate;
- (NSString *) stringFromState:(DFUControllerState) state;

- (void) setPeripheral:(CBPeripheral *)peripheral;
- (void) setFirmwareURL:(NSURL *) URL;

/*!
 * @brief This method must be invoked by Central Manager Delegate when the device has connected to the target peripheral.
 */
- (void) didConnect;
/*!
 * @brief This method must be invoked by Central Manager Delegate when the device has disconnected from the target peripheral.
 */
- (void) didDisconnect:(NSError *) error;

/*!
 * @brief Starts the DFU transfer process. The peripheral must be connected and services & characteristics must be discovered before calling this method.
 */
- (void) startTransfer;
/*!
 * @brief Pauses the transfer.
 * @warning This operation is not implemented.
 */
- (void) pauseTransfer;
/*!
 * @brief Cancels the transfer and resets the peripheral. The previous application or a DFU bootloader will be started on the target device.
 */
- (void) cancelTransfer;
@end
