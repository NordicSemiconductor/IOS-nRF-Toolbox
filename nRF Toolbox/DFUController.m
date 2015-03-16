//
//  DFUControllerStateMachine.m
//  nRF Loader
//
//  Created by Ole Morten on 10/22/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "DFUController.h"
#import "IntelHex2BinConverter.h"

#define DFUCONTROLLER_MAX_PACKET_SIZE 20

@interface DFUController ( )
@property (nonatomic) DFUControllerState state;
@property DFUTargetAdapter *target;

@property NSData *firmwareData;
@property NSUInteger firmwareDataBytesSent;
@property uint16_t notificationPacketInterval;

@property (nonatomic) float progress;
@property (strong, nonatomic) NSDate* startDate;

@end

@implementation DFUController
@synthesize state = _state;
@synthesize delegate = _delegate;
@synthesize uploadInterval = _uploadInterval;

+ (CBUUID *) serviceUUID
{
    return [[DFUTargetAdapter class] serviceUUID];
}

- (DFUController *) initWithDelegate:(id<DFUControllerDelegate>) delegate
{
    if (self = [super init])
    {
        _state = INIT;
        _delegate = delegate;
        
        _firmwareDataBytesSent = 0;
        
        _appName = @"-";
        _appSize = 0;
        
        _targetName = @"-";
        
        _progress = 0;

    }
    return self;
}

- (void) setPeripheral:(CBPeripheral *)peripheral
{
    self.targetName = peripheral.name;

    self.target = [[DFUTargetAdapter alloc] initWithDelegate:self];
    self.target.peripheral = peripheral;
}

- (void) setState:(DFUControllerState)newState
{
    @synchronized(self)
    {
        DFUControllerState oldState = _state;
        _state = newState;
        NSLog(@"State changed from %d to %d.", oldState, newState);
        
        if (newState == INIT)
        {
            self.progress = 0;
            self.firmwareDataBytesSent = 0;
        }
        
        [self.delegate didChangeState:newState];
    }
}

- (DFUControllerState) state
{
    return _state;
}

- (NSString *) stringFromState:(DFUControllerState) state
{
    switch (state)
    {
        case INIT:
            return @"Init";
        
        case DISCOVERING:
            return @"Discovering";
            
        case IDLE:
            return @"Ready";
            
        case SEND_NOTIFICATION_REQUEST:
        case SEND_START_COMMAND:
        case SEND_RECEIVE_COMMAND:
        case SEND_FIRMWARE_DATA:
        case WAIT_RECEIPT:
            return @"Uploading";
            
        case SEND_VALIDATE_COMMAND:
        case SEND_RESET:
            return @"Finishing";
            
        case FINISHED:
            return @"Finished";
            
        case CANCELED:
            return @"Canceled";
            
        case ERROR:
            return @"Error";
    }
    return nil;
}

-(unsigned long)binSize
{
    return self.firmwareData.length;
}

- (void) setFirmwareURL:(NSURL *)firmwareURL
{
    NSData* hexData = [NSData dataWithContentsOfURL:firmwareURL];
    self.firmwareData = [IntelHex2BinConverter convert:hexData];
    self.appName = firmwareURL.path.lastPathComponent;
    self.appSize = hexData.length;
    
    NSLog(@"Set firmware with size %lu, notificationPacketInterval: %d", (unsigned long)self.firmwareData.length, self.notificationPacketInterval);
}

- (void) setProgress:(float)progress
{
    _progress = progress;
    [self.delegate didUpdateProgress:progress];
}

/*!
 * @brief Sends the next part of data packets. If data receipes has been switched OFF in the app settings this will try to send all packets in a single loop.
 *        Disabling data packet receipt procedure may fail as the packet queue on iDeveice has limited size and the transfer is much slower than this method
 *        adds new packets. The method stores the position of the last packet that has been sent itself and continues from that point when called again.
 *        If all data packets before receipt notification has been send a (void)didWriteDataPacket method is called.
 *
 *        This method sets progress counter which causes [delegate didUpdateProgress:(float)progress] to be called.
 */
- (void) sendFirmwareChunk
{
    NSLog(@"sendFirmwareData");
    unsigned long currentDataSent = 0;
    
    for (int i = 0; (i < self.notificationPacketInterval || self.notificationPacketInterval == 0) && self.firmwareDataBytesSent < self.firmwareData.length; i++)
    {
        unsigned long length = (self.firmwareData.length - self.firmwareDataBytesSent) > DFUCONTROLLER_MAX_PACKET_SIZE ? DFUCONTROLLER_MAX_PACKET_SIZE : self.firmwareData.length - self.firmwareDataBytesSent;
        
        NSRange currentRange = NSMakeRange(self.firmwareDataBytesSent, length);
        NSData *currentData = [self.firmwareData subdataWithRange:currentRange];
        
        [self.target sendFirmwareData:currentData];
        
        self.firmwareDataBytesSent += length;
        self.progress = self.firmwareDataBytesSent / ((float) self.firmwareData.length);
        currentDataSent += length;
    }
    
    [self didWriteDataPacket];
    
    NSLog(@"Sent %lu bytes, total %u.", currentDataSent, self.firmwareDataBytesSent);
}

- (void) didConnect
{
    NSLog(@"didConnect");
    if (self.state == INIT)
    {
        self.state = DISCOVERING;
        [self.target startDiscovery];
    }
}

- (void) didDisconnect:(NSError *) error
{
    NSLog(@"didDisconnect");
    
    if (self.state != FINISHED && self.state != CANCELED && self.state != ERROR)
    {
        [self.delegate didDisconnect:error];
    }
    self.state = INIT;
}

- (void) didFinishDiscovery
{
    NSLog(@"didFinishDiscovery");
    if (self.state == DISCOVERING)
    {
        self.state = IDLE;
    }
}

- (void)didFinishDiscoveryWithError
{
    NSLog(@"didFinishDiscoveryWithError");
    if (self.state == DISCOVERING)
    {
        self.state = ERROR;
        [self.delegate didErrorOccurred:DEVICE_NOT_SUPPORTED];
    }
}

- (void) didReceiveResponse:(DFUTargetResponse) response forCommand:(DFUTargetOpcode) opcode
{
    NSLog(@"didReceiveResponse %d, in state %d", response, self.state);
    switch (self.state)
    {
        case SEND_START_COMMAND:
            if (response == SUCCESS)
            {
                self.state = SEND_RECEIVE_COMMAND;
                [self.target sendReceiveCommand];
            }
            else
            {
                self.state = ERROR;
                [self.delegate didErrorOccurred:response];
                [self.target sendResetAndActivate:NO];
            }
            break;
            
        case SEND_VALIDATE_COMMAND:
            if (response == SUCCESS)
            {
                self.state = SEND_RESET;
                [self.target sendResetAndActivate:YES];
            }
            else
            {
                self.state = ERROR;
                [self.delegate didErrorOccurred:response];
                [self.target sendResetAndActivate:NO];
            }
            break;
            
        case WAIT_RECEIPT:
            if (response == SUCCESS && opcode == RECEIVE_FIRMWARE_IMAGE)
            {
                self.progress = 1.0f;
                _uploadInterval = -[self.startDate timeIntervalSinceNow];
                self.state = SEND_VALIDATE_COMMAND;
                [self.target sendValidateCommand];
            }
            if (response != SUCCESS)
            {
                self.state = ERROR;
                [self.delegate didErrorOccurred:response];
                [self.target sendResetAndActivate:NO];
            }
            break;
        
        default:
            break;
    }
}

- (void) didReceiveReceipt
{
    NSLog(@"didReceiveReceipt");
    
    if (self.state == WAIT_RECEIPT)
    {        
        self.state = SEND_FIRMWARE_DATA;
        [self sendFirmwareChunk];
    }
}

- (void) didWriteControlPoint
{
    NSLog(@"didWriteControlPoint, state %d", self.state);
    
    switch (self.state)
    {
        case SEND_NOTIFICATION_REQUEST:
            self.state = SEND_START_COMMAND;
            [self.target sendStartCommand:(int) self.firmwareData.length];
            break;
        
        case SEND_RECEIVE_COMMAND:
            self.state = SEND_FIRMWARE_DATA;
            self.startDate = [NSDate date];
            [self sendFirmwareChunk];
            break;

        case SEND_RESET:
            self.state = FINISHED;
            [self.delegate didFinishTransfer];
            break;
            
        case CANCELED:
            [self.delegate didCancelTransfer];
            break;
            
        default:
            break;
    }
}

- (void) didWriteDataPacket
{
    NSLog(@"didWriteDataPacket");
    
    if (self.state == SEND_FIRMWARE_DATA)
    {
        self.state = WAIT_RECEIPT;
    }
}

- (void) startTransfer
{
    NSLog(@"startTransfer");
    
    if (self.state == IDLE)
    {
        // Read number of packet before receipt notification from app settings
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        [settings synchronize];
        if ([settings boolForKey:@"dfu_notifications"])
        {
            self.notificationPacketInterval = [settings integerForKey:@"dfu_number_of_packets"];
        }
        else
        {
            self.notificationPacketInterval = 0;
        }
        
        self.state = SEND_NOTIFICATION_REQUEST;
        [self.target sendNotificationRequest:self.notificationPacketInterval];
    }
}

- (void) pauseTransfer
{
    NSLog(@"pauseTransfer");
}

- (void) cancelTransfer
{
    NSLog(@"cancelTransfer");
    
    if (self.state != INIT && self.state != CANCELED && self.state != FINISHED)
    {
        self.state = CANCELED;
        [self.target sendResetAndActivate:NO];
    }
}

@end
