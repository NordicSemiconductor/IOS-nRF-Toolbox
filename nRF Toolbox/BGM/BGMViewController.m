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

#import "BGMViewController.h"
#import "BGMItemCell.h"
#import "GlucoseReading.h"
#import "RecordAccess.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "CharacteristicReader.h"

//enum
//{
//    ACTION_REFRESH,
//    ACTION_ALL_RECORDS,
//    ACTION_FIRST_RECORD,
//    ACTION_LAST_RECORD,
//    ACTION_CLEAR,
//    ACTION_DELETE_ALL,
//    ACTION_CANCEL
//};

@interface BGMViewController () {
    NSDateFormatter *dateFormat;
    
    CBUUID *bgmServiceUUID;
    CBUUID *bgmGlucoseMeasurementCharacteristicUUID;
    CBUUID *bgmGlucoseMeasurementContextCharacteristicUUID;
    CBUUID *bgmRecordAccessControlPointCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;
@property (strong, nonatomic) CBCharacteristic* bgmRecordAccessControlPointCharacteristic;
@property (strong, nonatomic) NSMutableArray* readings;
@property (weak, nonatomic) IBOutlet UITableView *bgmTableView;

- (IBAction)actionButtonClicked:(id)sender;
- (IBAction)aboutButtonClicked:(id)sender;

@end

@implementation BGMViewController
@synthesize bluetoothManager;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;
@synthesize bgmTableView;
@synthesize recordButton;
@synthesize readings;
@synthesize bgmRecordAccessControlPointCharacteristic;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        readings = [NSMutableArray arrayWithCapacity:20];
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd.MM.yyyy, hh:mm"];
        
        bgmServiceUUID = [CBUUID UUIDWithString:bgmServiceUUIDString];
        bgmGlucoseMeasurementCharacteristicUUID = [CBUUID UUIDWithString:bgmGlucoseMeasurementCharacteristicUUIDString];
        bgmGlucoseMeasurementContextCharacteristicUUID = [CBUUID UUIDWithString:bgmGlucoseMeasurementContextCharacteristicUUIDString];
        bgmRecordAccessControlPointCharacteristicUUID = [CBUUID UUIDWithString:bgmRecordAccessControlPointCharacteristicUUIDString];
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Decode the characteristic data
    NSData *data = characteristic.value;
    uint8_t *array = (uint8_t*) data.bytes;
    
    if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID])
    {
        uint8_t batteryLevel = [CharacteristicReader readUInt8Value:&array];
        NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
        
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [battery setTitle:text forState:UIControlStateDisabled];
        });
        
        if (battery.tag == 0)
        {
            // If battery level notifications are available, enable them
            if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
            {
                battery.tag = 1; // mark that we have enabled notifications
                
                // Enable notification on data characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
    else if ([characteristic.UUID isEqual:bgmGlucoseMeasurementCharacteristicUUID])
    {
        GlucoseReading* reading = [GlucoseReading readingFromBytes:array];
        if ([readings containsObject:reading])
        {
            // If the reading has been found (the same reading has the same sequence number), replace it with the new one
            // The indexIfObjext method uses isEqual method from GlucodeReading (comparing by sequence number only)
            [readings replaceObjectAtIndex:[readings indexOfObject:reading] withObject:reading];
        }
        else
        {
            // If not, just add the new one to the array
            [readings addObject:reading];
        }
    }
    else if ([characteristic.UUID isEqual:bgmGlucoseMeasurementContextCharacteristicUUID])
    {
        //uint8_t test[] = { 0x5F, 0x00, 0x00, 0x02, 0x01, 0xF0, 0x03, 0x13, 0xF2, 0x00, 0x22, 0x03, 0x03, 0xF0, 0x01, 0xE0 };// test data
        GlucoseReadingContext* context = [GlucoseReadingContext readingContextFromBytes:array];
        // The indexIfObjext method uses isEqual method from GlucodeReadingContext (comparing with GlucoseReading by sequence number)
        NSInteger index = [readings indexOfObject:context];
        if (index != NSNotFound)
        {
            GlucoseReading* reading = [readings objectAtIndex:index];
            reading.context = context;
        }
        else
        {
            NSLog(@"Glucose Measurement with seq no %d not found", context.sequenceNumber);
        }
    }
    else if ([characteristic.UUID isEqual:bgmRecordAccessControlPointCharacteristicUUID])
    {
        RecordAccessParam* param = (RecordAccessParam*) array;
        
        dispatch_async(dispatch_get_main_queue(), ^{
        switch (param->value.response.responseCode)
        {
            case SUCCESS:
            {
                // Refresh the table
               [bgmTableView reloadData];
                break;
            }
                
            case OP_CODE_NOT_SUPPORTED:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Operation not supported" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                break;
            }
                
            case NO_RECORDS_FOUND:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status" message:@"No records found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                break;
            }
                
            case OPERATOR_NOT_SUPPORTED:
                NSLog(@"Operator not supported");
                break;
                
            case INVALID_OPERATOR:
                NSLog(@"Invalid operator");
                break;
                
            case OPERAND_NOT_SUPPORTED:
                NSLog(@"Operand not supported");
                break;
                
            case INVALID_OPERAND:
                NSLog(@"Invalid operand");
                break;
                
            default:
                NSLog(@"Response:");
                NSLog(@"Op code: %d, operator %d", param->opCode, param->operatorType);
                NSLog(@"Req Op Code: %d, response: %d", param->value.response.requestOpCode, param->value.response.responseCode);
                break;
            }
        });
    }
}


@end
