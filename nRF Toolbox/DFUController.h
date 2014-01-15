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
- (void) didChangeState:(DFUControllerState) state;
- (void) didUpdateProgress:(float) progress;
- (void) didFinishTransfer;
- (void) didCancelTransfer;
- (void) didErrorOccurred:(DFUTargetResponse) error;
- (void) didDisconnect:(NSError *) error;
@end

@interface DFUController : NSObject <DFUTargetAdapterDelegate>
@property (strong, nonatomic) id<DFUControllerDelegate> delegate;

@property (copy, nonatomic) NSString *appName;
@property (assign, nonatomic) unsigned long appSize;
@property (readonly, nonatomic) unsigned long binSize;
@property (nonatomic) NSTimeInterval uploadInterval;

@property (copy, nonatomic) NSString *targetName;

+ (CBUUID *) serviceUUID;

- (DFUController *) initWithDelegate:(id<DFUControllerDelegate>) delegate;
- (NSString *) stringFromState:(DFUControllerState) state;

- (void) setPeripheral:(CBPeripheral *)peripheral;
- (void) setFirmwareURL:(NSURL *) URL;

- (void) didConnect;
- (void) didDisconnect:(NSError *) error;

- (void) startTransfer;
- (void) pauseTransfer;
- (void) cancelTransfer;
@end
