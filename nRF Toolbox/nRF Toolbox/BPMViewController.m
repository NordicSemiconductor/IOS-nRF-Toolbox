//
//  BPMViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 10/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "BPMViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "CharacteristicReader.h"
#import "HelpViewController.h"

@interface BPMViewController () {
    CBUUID *bpmServiceUUID;
    CBUUID *bpmBloodPressureMeasurementCharacteristicUUID;
    CBUUID *bpmIntermediateCuffPressureCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@property (weak, nonatomic) IBOutlet UILabel *systolic;
@property (weak, nonatomic) IBOutlet UILabel *systolicUnit;
@property (weak, nonatomic) IBOutlet UILabel *diastolic;
@property (weak, nonatomic) IBOutlet UILabel *diastolicUnit;
@property (weak, nonatomic) IBOutlet UILabel *meanAp;
@property (weak, nonatomic) IBOutlet UILabel *meanApUnit;
@property (weak, nonatomic) IBOutlet UILabel *pulse;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

@end

@implementation BPMViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        bpmServiceUUID = [CBUUID UUIDWithString:bpmServiceUUIDString];
        bpmBloodPressureMeasurementCharacteristicUUID = [CBUUID UUIDWithString:bpmBloodPressureMeasurementCharacteristicUUIDString];
        bpmIntermediateCuffPressureCharacteristicUUID = [CBUUID UUIDWithString:bpmIntermediateCuffPressureCharacteristicUUIDString];
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad
{
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    //    UILocalNotification *notification = [[UILocalNotification alloc]init];
    //    notification.alertAction = @"Show";
    //    notification.alertBody = @"You are still connected to Running Speed and Cadence sensor. It will collect data also in background.";
    //    notification.hasAction = NO;
    //    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    //    notification.timeZone = [NSTimeZone  defaultTimeZone];
    //    notification.soundName = UILocalNotificationDefaultSoundName;
    //    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    //    [[UIApplication sharedApplication] cancelAllLocalNotifications];
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
        controller.filterUUID = bpmServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText =[NSString stringWithFormat:@"-BPM (Blood Pressure Monitor) profile allows you to connect to your Blood Pressure device.\n\n-It supports the cuff pressure notifications and displays systolic, diastolic and mean arterial pulse values as well as the pulse after blood pressure reading is completed."];
    }
}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // Some devices disconnects just after finishing measurement so we have to clear the UI before new connection, not after previous.
    [self clearUI];
    
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    peripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:peripheral options:options];
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
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[bpmServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void) clearUI
{
    [deviceName setText:@"DEFAULT BPM"];
    battery.tag = 0;
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    
    self.systolicUnit.hidden = YES;
    self.diastolicUnit.hidden = YES;
    self.meanApUnit.hidden = YES;
    
    self.systolic.text = @"-";
    self.diastolic.text = @"-";
    self.meanAp.text = @"-";
    self.pulse.text = @"-";
    self.timestamp.text = @"n/a";
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
        if ([service.UUID isEqual:bpmServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[bpmBloodPressureMeasurementCharacteristicUUID, bpmIntermediateCuffPressureCharacteristicUUID] forService:service];
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
    if ([service.UUID isEqual:bpmServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:bpmBloodPressureMeasurementCharacteristicUUID] ||
                [characteristic.UUID isEqual:bpmIntermediateCuffPressureCharacteristicUUID])
            {
                // Enable notifications and indications on data characteristics
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    } else if ([service.UUID isEqual:batteryServiceUUID])
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
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        // Decode the characteristic data
        NSData *data = characteristic.value;
        uint8_t *array = (uint8_t*) data.bytes;
        
        if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID])
        {
            UInt8 batteryLevel = [CharacteristicReader readUInt8Value:&array];
            NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
            [battery setTitle:text forState:UIControlStateDisabled];
            
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
        else if ([characteristic.UUID isEqual:bpmBloodPressureMeasurementCharacteristicUUID] ||
                 [characteristic.UUID isEqual:bpmIntermediateCuffPressureCharacteristicUUID])
        {
            UInt8 flags = [CharacteristicReader readUInt8Value:&array];
            BOOL kPa = (flags & 0x01) > 0;
            BOOL timestampPresent = (flags & 0x02) > 0;
            BOOL pulseRatePresent = (flags & 0x04) > 0;
            
            // Update units
            if (kPa)
            {
                self.systolicUnit.text = @"kPa";
                self.diastolicUnit.text = @"kPa";
                self.meanApUnit.text = @"kPa";
            }
            else
            {
                self.systolicUnit.text = @"mmHg";
                self.diastolicUnit.text = @"mmHg";
                self.meanApUnit.text = @"mmHg";
            }
            
            // Read main values
            if ([characteristic.UUID isEqual:bpmBloodPressureMeasurementCharacteristicUUID])
            {
                float systolicValue = [CharacteristicReader readSFloatValue:&array];
                float diastolicValue = [CharacteristicReader readSFloatValue:&array];
                float meanApValue = [CharacteristicReader readSFloatValue:&array];
                
                self.systolic.text = [NSString stringWithFormat:@"%.1f", systolicValue];
                self.diastolic.text = [NSString stringWithFormat:@"%.1f", diastolicValue];
                self.meanAp.text = [NSString stringWithFormat:@"%.1f", meanApValue];
                
                self.systolicUnit.hidden = NO;
                self.diastolicUnit.hidden = NO;
                self.meanApUnit.hidden = NO;
            }
            else
            {
                float systolicValue = [CharacteristicReader readSFloatValue:&array];
                array += 4;
                
                self.systolic.text = [NSString stringWithFormat:@"%.1f", systolicValue];
                self.diastolic.text = @"n/a";
                self.meanAp.text = @"n/a";
                
                self.systolicUnit.hidden = NO;
                self.diastolicUnit.hidden = YES;
                self.meanApUnit.hidden = YES;
            }
            
            // Read timestamp
            if (timestampPresent)
            {
                NSDate* date = [CharacteristicReader readDateTime:&array];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd.MM.yyyy, hh:mm"];
                NSString* dateFormattedString = [dateFormat stringFromDate:date];
                
                self.timestamp.text = dateFormattedString;
            }
            else
            {
                self.timestamp.text = @"n/a";
            }
            
            // Read pulse
            if (pulseRatePresent)
            {
                float pulseValue = [CharacteristicReader readSFloatValue:&array];
                self.pulse.text = [NSString stringWithFormat:@"%.1f", pulseValue];
            }
            else
            {
                self.pulse.text = @"-";
            }
        }
    });
}

@end
