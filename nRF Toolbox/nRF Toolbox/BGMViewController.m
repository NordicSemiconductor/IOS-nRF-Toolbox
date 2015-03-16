//
//  BGMViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 10/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "BGMViewController.h"
#import "BGMDetailsViewController.h"
#import "BGMItemCell.h"
#import "ScannerViewController.h"
#import "GlucoseReading.h"
#import "RecordAccess.h"
#import "Constants.h"
#import "CharacteristicReader.h"
#import "HelpViewController.h"

enum
{
    ACTION_REFRESH,
    ACTION_ALL_RECORDS,
    ACTION_FIRST_RECORD,
    ACTION_LAST_RECORD,
    ACTION_CLEAR,
    ACTION_DELETE_ALL,
    ACTION_CANCEL
};

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
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;

- (IBAction)actionButtonClicked:(id)sender;

@end

@implementation BGMViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;
@synthesize bgmTableView;
//@synthesize actionButton;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
    
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformMakeRotation(-M_PI / 2);
    
    bgmTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionButtonClicked:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    
    [actionSheet addButtonWithTitle:@"Refresh"];
    [actionSheet addButtonWithTitle:@"All"];
    [actionSheet addButtonWithTitle:@"First"];
    [actionSheet addButtonWithTitle:@"Last"];
    [actionSheet addButtonWithTitle:@"Clear"];
    [actionSheet addButtonWithTitle:@"Delete All"];
    [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet setDestructiveButtonIndex:ACTION_DELETE_ALL];
    [actionSheet setCancelButtonIndex:ACTION_CANCEL];
    
    //[actionSheet showFromBarButtonItem:actionButton animated:YES];
    [actionSheet showInView:self.view];
}

- (IBAction)connectOrDisconnectClicked {
    if (connectedPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || connectedPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = bgmServiceUUID;
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"details"])
    {
        BGMDetailsViewController *controller = (BGMDetailsViewController *)segue.destinationViewController;
        controller.reading = [readings objectAtIndex:[bgmTableView indexPathForSelectedRow].row];
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText =[NSString stringWithFormat:@"-BGM (BLOOD GLUCOSE MONITOR) profile allows you to connect to your Glucose sensor.\n\n-You can read the history of glucose records."];
    }

}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    peripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:peripheral options:options];
}

#pragma mark Table View Datasource delegate methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return readings.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BGMItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BGMCell"];
    
    GlucoseReading* reading = [readings objectAtIndex:indexPath.row];
    cell.timestamp.text = [dateFormat stringFromDate:reading.timestamp];
    if (reading.glucoseConcentrationTypeAndLocationPresent)
    {
        cell.value.text = [NSString stringWithFormat:@"%.1f", reading.glucoseConcentration];
        cell.type.text = [reading typeAsString];
    }
    else
    {
        cell.value.text = @"-";
        cell.type.text = @"Unavailable";
    }
    
    return cell;
}

#pragma mark Action Sheet delegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Cancel button pressed?
    if (buttonIndex == ACTION_CANCEL)
        return;
    
    RecordAccessParam param;
    NSInteger size = 0;
    BOOL clearList = YES;
    switch (buttonIndex)
    {
        case ACTION_REFRESH:
        {
            if ([readings count] > 0)
            {
                param.opCode = REPORT_STORED_RECORDS;
                param.operatorType = GREATER_THAN_OR_EQUAL;
                param.value.singleParam.filterType = SEQUENCE_NUMBER;
                GlucoseReading* reading = [readings objectAtIndex:([readings count] - 1)];
                param.value.singleParam.paramLE = CFSwapInt16HostToLittle(reading.sequenceNumber);
                size = 5;
                clearList = NO;
                break;
            } // else, obtain all records
        }
        case ACTION_ALL_RECORDS:
        {
            param.opCode = REPORT_STORED_RECORDS;
            param.operatorType = ALL_RECORDS;
            size = 2;
            break;
        }
        case ACTION_FIRST_RECORD:
        {
            param.opCode = REPORT_STORED_RECORDS;
            param.operatorType = FIRST_RECORD;
            size = 2;
            break;
        }
        case ACTION_LAST_RECORD:
        {
            param.opCode = REPORT_STORED_RECORDS;
            param.operatorType = LAST_RECORD;
            size = 2;
            break;
        }
        case ACTION_CLEAR:
        {
            // do nothing
            break;
        }
        case ACTION_DELETE_ALL:
        {
            param.opCode = DELETE_STORED_RECORDS;
            param.operatorType = ALL_RECORDS;
            size = 2;
            break;
        }
    }
    
    // Clear the current view
    if (clearList)
    {
        [readings removeAllObjects];
        [bgmTableView reloadData];
    }
    
    if (size > 0)
    {
        NSData* data = [NSData dataWithBytes:&param length:size];
        [connectedPeripheral writeValue:data forCharacteristic:bgmRecordAccessControlPointCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark Central Manager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        // TODO
    }
    else
    {
        // TODO
        NSLog(@"Bluetooth not ON");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [deviceName setText:peripheral.name];
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        [self enableRecordButton];
    });
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[bgmServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        [self disableRecordButton];
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        [self disableRecordButton];        
        [self clearUI];
    });
}

- (void) clearUI
{
    [readings removeAllObjects];
    [bgmTableView reloadData];
    
    [deviceName setText:@"DEFAULT BGM"];
    battery.tag = 0;
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
}

-(void) enableRecordButton
{
    recordButton.enabled = YES;
    [recordButton setBackgroundColor:[UIColor blackColor]];
    [recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) disableRecordButton
{
    recordButton.enabled = NO;
    [recordButton setBackgroundColor:[UIColor lightGrayColor]];
    [recordButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
}

#pragma mark Peripheral delegate methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:bgmServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[bgmGlucoseMeasurementCharacteristicUUID, bgmGlucoseMeasurementContextCharacteristicUUID, bgmRecordAccessControlPointCharacteristicUUID] forService:service];
        }
        else if ([service.UUID isEqual:batteryServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[batteryLevelCharacteristicUUID] forService:service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Characteristics for one of those services has been found
    if ([service.UUID isEqual:bgmServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:bgmGlucoseMeasurementCharacteristicUUID] ||
                [characteristic.UUID isEqual:bgmGlucoseMeasurementContextCharacteristicUUID])
            {
                // Enable notification on data characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else if ([characteristic.UUID isEqual:bgmRecordAccessControlPointCharacteristicUUID])
            {
                bgmRecordAccessControlPointCharacteristic = characteristic;
                
                // Enable notification on data characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
    else if ([service.UUID isEqual:batteryServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID])
            {
                // Read the current battery value
                [peripheral readValueForCharacteristic:characteristic];
                break;
            }
        }
    }
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
