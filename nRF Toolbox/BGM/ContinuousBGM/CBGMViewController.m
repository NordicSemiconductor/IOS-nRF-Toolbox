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

#import "CBGMViewController.h"
#import "CBGMDetailsViewController.h"
#import "CBGMItemCell.h"
#import "ScannerViewController.h"
#import "GlucoseReading.h"
#import "CGMSpecificOperations.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "CharacteristicReader.h"

enum
{
    ACTION_START_SESSION,
    ACTION_STOP_SESSION,
    ACTION_SET_TIMER
};

@interface CBGMViewController () {
    NSDateFormatter *dateFormat;
    
    CBUUID *cbgmServiceUUID;
    CBUUID *cgmGlucoseMeasurementCharacteristicUUID;
    CBUUID *cgmGlucoseMeasurementContextCharacteristicUUID;
    CBUUID *cgmRecordAccessControlPointCharacteristicUUID;
    CBUUID *cgmFeatureCharacteristicUUID;
    CBUUID *cgmStatusCharacteristicUUID;
    CBUUID *cgmSessionStartTimeCharacteristicUUID;
    CBUUID *cgmSessionRunTimeCharacteristicUUID;
    CBUUID *cgmSpecificOpsControlPointCharacteristicUUID;
    
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;
@property (strong, nonatomic) CBCharacteristic* cgmRecordAccessControlPointCharacteristic;
@property (strong, nonatomic) CBCharacteristic* cgmSpecificOpsControlPointCharacteristic;
@property (strong, nonatomic) NSMutableArray* readings;
@property (weak, nonatomic) IBOutlet UITableView *cbgmTableView;

- (IBAction)actionButtonClicked:(id)sender;
- (IBAction)aboutButtonClicked:(id)sender;

@end

@implementation CBGMViewController
@synthesize bluetoothManager;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;
@synthesize cbgmTableView;
@synthesize recordButton;
@synthesize readings;
@synthesize cgmSpecificOpsControlPointCharacteristic;
@synthesize cgmRecordAccessControlPointCharacteristic;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        readings = [NSMutableArray arrayWithCapacity:20];
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd.MM.yyyy, hh:mm"];
        
        cbgmServiceUUID = [CBUUID UUIDWithString:cgmServiceUUIDString];
        cgmGlucoseMeasurementCharacteristicUUID         = [CBUUID UUIDWithString:cgmGlucoseMeasurementCharacteristicUUIDString];
        cgmGlucoseMeasurementContextCharacteristicUUID  = [CBUUID UUIDWithString:bgmGlucoseMeasurementContextCharacteristicUUIDString];
        cgmRecordAccessControlPointCharacteristicUUID   = [CBUUID UUIDWithString:bgmRecordAccessControlPointCharacteristicUUIDString];
        cgmFeatureCharacteristicUUID                    = [CBUUID UUIDWithString:cgmFeatureCharacteristicUUIDString];
        cgmStatusCharacteristicUUID                     = [CBUUID UUIDWithString:cgmStatusCharacteristicUUIDString];
        cgmSessionStartTimeCharacteristicUUID           = [CBUUID UUIDWithString:cgmSessionStartTimeCharacteristicUUIDString];
        cgmSessionRunTimeCharacteristicUUID             = [CBUUID UUIDWithString:cgmSessionRunTimeCharacteristicUUIDString];
        cgmSpecificOpsControlPointCharacteristicUUID    = [CBUUID UUIDWithString:cgmSpecificOpsControlPointCharacteristicUUIDString];

        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0f, 0.0f), (float)(-M_PI / 2));
    
    cbgmTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ peripheral. It will collect data also in background.",connectedPeripheral.name]];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (IBAction)actionButtonClicked:(id)sender {

    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:@"Start Session"];
    [actionSheet addButtonWithTitle:@"Stop Session"];
    [actionSheet addButtonWithTitle:@"Set interval: 1 Min."];
    [actionSheet setDestructiveButtonIndex:1];

    [actionSheet showInView:self.view];

}

- (IBAction)aboutButtonClicked:(id)sender {
    [self showAbout:[AppUtilities getCBGMHelpText]];
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
        UINavigationController *nc = segue.destinationViewController;
        ScannerViewController *controller = (ScannerViewController *)nc.childViewControllerForStatusBarHidden;
        controller.filterUUID = cbgmServiceUUID;
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"details"])
    {
        CBGMDetailsViewController *controller = (CBGMDetailsViewController *)segue.destinationViewController;
        controller.reading = [readings objectAtIndex:[cbgmTableView indexPathForSelectedRow].row];
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
    CBGMItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CBGMCell"];
    
    GlucoseReading* reading = [readings objectAtIndex:indexPath.row];
    cell.timestamp.text = [dateFormat stringFromDate:reading.timestamp];
    if (reading.glucoseConcentrationTypeAndLocationPresent)
    {
        cell.type.text = [reading typeAsString];
        if (reading.unit == MOL_L)
        {
            cell.value.text = [NSString stringWithFormat:@"%.1f", reading.glucoseConcentration * 1000.0f]; // converting mol/l -> mmol/l
            cell.unit.text = @"mmol/L";
        }
        else
        {
            cell.value.text = [NSString stringWithFormat:@"%.0f", reading.glucoseConcentration * 100000.0f]; // converting kg/l -> mg/dl
            cell.unit.text = @"mg/dL";
        }
    }
    else
    {
        cell.value.text = @"-";
        cell.type.text = @"Unavailable";
        cell.unit.text = @"";
    }
    
    return cell;
}

#pragma mark Action Sheet delegate methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
   
    SpecficOpsParam param;
    NSInteger size = 0;
    BOOL clearList = NO;
    CBCharacteristic *targetCharacteristic = Nil;
    
    switch (buttonIndex)
    {
        case ACTION_START_SESSION:
        {
            NSLog(@"Start session");
            param.opCode = START_SESSION;
            size = 1;
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic;
            break;
        }
        case ACTION_STOP_SESSION:
        {
            NSLog(@"Stop session");
            param.opCode = STOP_SESSION;
            size = 1;
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic;
            break;
        }
        case ACTION_SET_TIMER:
        {
            NSLog(@"Set interval to 1 Min");
            param.opCode = SET_COMMUNICATION_INTERVAL;
            param.operatorType = 1;
            size = 2;
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic;
        }
    }
    
    // Clear the current view
    if (clearList)
    {
        [readings removeAllObjects];
        [cbgmTableView reloadData];
    }

    if(size > 0) {
        NSData* data = [NSData dataWithBytes:&param length:size];
        [connectedPeripheral writeValue:data forCharacteristic:targetCharacteristic type:CBCharacteristicWriteWithResponse];
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
        //Following if condition display user permission alert for background notification
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];

    });
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[cbgmServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
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
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected",peripheral.name]];
        }
        connectedPeripheral = nil;
        [self disableRecordButton];        
        [self clearUI];        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void) clearUI
{
    [readings removeAllObjects];
    [cbgmTableView reloadData];
    
    [deviceName setText:@"DEFAULT CGM"];
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
        if ([service.UUID isEqual:cbgmServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[cgmGlucoseMeasurementCharacteristicUUID,
                                                           cgmGlucoseMeasurementContextCharacteristicUUID,
                                                           cgmRecordAccessControlPointCharacteristicUUID,
                                                           cgmFeatureCharacteristicUUID,
                                                           cgmStatusCharacteristicUUID,
                                                           cgmSessionStartTimeCharacteristicUUID,
                                                           cgmSessionRunTimeCharacteristicUUID,
                                                           cgmSpecificOpsControlPointCharacteristicUUID]
                                              forService:service];
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
    if ([service.UUID isEqual:cbgmServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            if ([characteristic.UUID isEqual:cgmRecordAccessControlPointCharacteristicUUID])
            {
                cgmRecordAccessControlPointCharacteristic = characteristic;
            }
            else if ([characteristic.UUID isEqual:cgmSpecificOpsControlPointCharacteristicUUID])
            {
                cgmSpecificOpsControlPointCharacteristic = characteristic;
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
    else if ([characteristic.UUID isEqual:cgmGlucoseMeasurementCharacteristicUUID])
    {
        SpecficOpsParam* param = (SpecficOpsParam*) array;

        NSLog(@"Measurement response Code: %d, array: %@", param->value.response.responseCode, [data description]);
        dispatch_async(dispatch_get_main_queue(), ^{
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
            [cbgmTableView reloadData];
        });
//        NSLog(@"Response code: %d", param->value.response.responseCode);
//
//        switch (param->value.response.responseCode)
//        {
//            case SUCCESS:
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    GlucoseReading* reading = [GlucoseReading readingFromBytes:array];
//                    if ([readings containsObject:reading])
//                    {
//                        // If the reading has been found (the same reading has the same sequence number), replace it with the new one
//                        // The indexIfObjext method uses isEqual method from GlucodeReading (comparing by sequence number only)
//                        [readings replaceObjectAtIndex:[readings indexOfObject:reading] withObject:reading];
//                    }
//                    else
//                    {
//                        // If not, just add the new one to the array
//                        [readings addObject:reading];
//                    }
//                   [cbgmTableView reloadData];
//                });
//                break;
//            }
//
//            case OP_CODE_NOT_SUPPORTED:
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Operation not supported" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//                    [alert show];
//                });
//                break;
//            }
//
//            default:
//                NSLog(@"Response:");
//                NSLog(@"Op code: %d, operator %d", param->opCode, param->operatorType);
//                NSLog(@"Req Op Code: %d, response: %d", param->value.response.requestOpCode, param->value.response.responseCode);
//            break;
//        }
    }
    else if ([characteristic.UUID isEqual:cgmGlucoseMeasurementContextCharacteristicUUID])
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
    else if ([characteristic.UUID isEqual:cgmSpecificOpsControlPointCharacteristicUUID]){
        SpecficOpsParam* param = (SpecficOpsParam*) array;
    
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (param->value.response.responseCode)
            {
                default:
                    NSLog(@"Op code: %d, operator %d", param->opCode, param->operatorType);
                    NSLog(@"Req Op Code: %d, response: %d", param->value.response.requestOpCode, param->value.response.responseCode);
                    break;
            }
        });
        return;
    }
    else if ([characteristic.UUID isEqual:cgmSessionStartTimeCharacteristicUUID]){
        NSLog(@"Start time did update");
    }
    else if ([characteristic.UUID isEqual:cgmSessionRunTimeCharacteristicUUID]){
        NSLog(@"runtime did update");
    }else{
        NSLog(@"Other characteristic update");
    }
}


@end
