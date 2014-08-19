//
//  TargetController.m
//  nRF Loader
//
//  Created by Ole Morten on 10/8/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "DFUTargetAdapter.h"
#import "Constants.h"

typedef struct __attribute__((packed))
{
    uint8_t opcode;
    union
    {
        uint16_t n_packets;
        struct __attribute__((packed))
        {
            uint8_t   original;
            uint8_t   response;
        };
        uint32_t n_bytes;
    };
} dfu_control_point_data_t;

@interface DFUTargetAdapter ()
@property CBCharacteristic *controlPointCharacteristic;
@property CBCharacteristic *packetCharacteristic;

@property id<DFUTargetAdapterDelegate> delegate;
@end

@implementation DFUTargetAdapter
@synthesize peripheral = _peripheral;
@synthesize controlPointCharacteristic = _controlPointCharacteristic;
@synthesize packetCharacteristic = _packetCharacteristic;

+ (CBUUID *) serviceUUID
{
    return [CBUUID UUIDWithString:dfuServiceUUIDString];
}

+ (CBUUID *) controlPointCharacteristicUUID
{
    return [CBUUID UUIDWithString:dfuControlPointCharacteristicUUIDString];
}

+ (CBUUID *) packetCharacteristicUUID
{
    return [CBUUID UUIDWithString:dfuPacketCharacteristicUUIDString];
}

- (DFUTargetAdapter *) initWithDelegate:(id<DFUTargetAdapterDelegate>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
    }
    return self;
}

- (void) setPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"setPeripheral");
    _peripheral = peripheral;
    _peripheral.delegate = self;
}

- (void) startDiscovery
{
    NSLog(@"startDiscovery");
    [self.peripheral discoverServices:@[[self.class serviceUUID]]];
}

- (void) sendNotificationRequest:(uint16_t) interval
{
    NSLog(@"sendNotificationRequest");
    dfu_control_point_data_t data;
    data.opcode = REQUEST_RECEIPT;
    data.n_packets = interval;
    
    NSData *commandData = [NSData dataWithBytes:&data length:3];
    [self.peripheral writeValue:commandData forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) sendStartCommand:(int) firmwareLength
{
    NSLog(@"sendStartCommand");
    dfu_control_point_data_t data;
    data.opcode = START_DFU;
    
    NSData *commandData = [NSData dataWithBytes:&data length:1];
    [self.peripheral writeValue:commandData forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
    
    NSData *sizeData = [NSData dataWithBytes:&firmwareLength length:sizeof(firmwareLength)];
    [self.peripheral writeValue:sizeData forCharacteristic:self.packetCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void) sendReceiveCommand
{
    NSLog(@"sendReceiveCommand");
    dfu_control_point_data_t data;
    data.opcode = RECEIVE_FIRMWARE_IMAGE;
    
    NSData *commandData = [NSData dataWithBytes:&data length:1];
    [self.peripheral writeValue:commandData forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) sendFirmwareData:(NSData *) data
{
    [self.peripheral writeValue:data forCharacteristic:self.packetCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void) sendValidateCommand
{
    NSLog(@"sendValidateCommand");
    dfu_control_point_data_t data;
    data.opcode = VALIDATE_FIRMWARE;
    
    NSData *commandData = [NSData dataWithBytes:&data length:1];
    [self.peripheral writeValue:commandData forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) sendResetAndActivate:(BOOL)activate
{
    if (!self.controlPointCharacteristic)
    {
        return;
    }
    
    NSLog(@"sendResetAndActivate %d", activate);
    dfu_control_point_data_t data;
    
    if (activate)
    {
        data.opcode = ACTIVATE_RESET;
    }
    else
    {
        data.opcode = RESET;
    }
    
    NSData *commandData = [NSData dataWithBytes:&data length:1];
    [self.peripheral writeValue:commandData forCharacteristic:self.controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverServices failed: %@", error);
        return;
    }
    
    NSLog(@"didDiscoverServices succeeded.");
    
    for (CBService *s in peripheral.services)
    {
        if ([s.UUID isEqual:[self.class serviceUUID]])
        {
            NSLog(@"Discover characteristics...");
            [self.peripheral discoverCharacteristics:@[[self.class controlPointCharacteristicUUID], [self.class packetCharacteristicUUID]] forService:s];
            return;
        }
    }
    [self.delegate didFinishDiscoveryWithError];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristics failed: %@", error);
        return;
    }
    
    NSLog(@"didDiscoverCharacteristics succeeded.");
    
    for (CBCharacteristic *c in service.characteristics)
    {
        if ([c.UUID isEqual:[self.class controlPointCharacteristicUUID]])
        {
            NSLog(@"Found control point characteristic.");
            self.controlPointCharacteristic = c;
            
            [self.peripheral setNotifyValue:YES forCharacteristic:self.controlPointCharacteristic];
        }
        else if ([c.UUID isEqual:[self.class packetCharacteristicUUID]])
        {
            NSLog(@"Found packet characteristic.");
            self.packetCharacteristic = c;
        }
    }
    
    if (self.packetCharacteristic && self.controlPointCharacteristic)
    {
        [self.delegate didFinishDiscovery];
    }
    else
    {
        [self.delegate didFinishDiscoveryWithError];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

    NSLog(@"Did update value for characteristic %@. Value: %@.", characteristic, characteristic.value);
    if ([characteristic.UUID isEqual:[self.class controlPointCharacteristicUUID]])
    {
        dfu_control_point_data_t *packet = (dfu_control_point_data_t *) characteristic.value.bytes;
        if (packet->opcode == RESPONSE_CODE)
        {
            [self.delegate didReceiveResponse:packet->response forCommand:packet->original];
        }
        if (packet->opcode == RECEIPT)
        {
            [self.delegate didReceiveReceipt];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (characteristic == self.controlPointCharacteristic)
    {
        [self.delegate didWriteControlPoint];
    }
}
@end
