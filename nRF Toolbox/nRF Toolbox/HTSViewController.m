//
//  HTSViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 09/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "HTSViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "CharacteristicReader.h"
#import "HelpViewController.h"

@interface HTSViewController () {
    CBUUID *htsServiceUUID;
    CBUUID *htsMeasurementCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral* connectedPeripheral;

-(void) updateUnits;

@end

@implementation HTSViewController {
    BOOL fahrenheit;
    float temperatureValue;
}
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;
@synthesize degreeControl;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        htsServiceUUID = [CBUUID UUIDWithString:htsServiceUUIDString];
        htsMeasurementCharacteristicUUID = [CBUUID UUIDWithString:htsMeasurementCharacteristicUUIDString];
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
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
    
    [self updateUnits];
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
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [self updateUnits];
}

- (void) updateUnits
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    fahrenheit = [[NSUserDefaults standardUserDefaults] boolForKey:@"fahrenheit"];
    if (fahrenheit)
    {
        degreeControl.selectedSegmentIndex = 1;
        [self.degrees setText:@"°F"];
    }
    else
    {
        degreeControl.selectedSegmentIndex = 0;
        [self.degrees setText:@"°C"];
    }
}

- (IBAction)connectOrDisconnectClicked {
    if (connectedPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
    }
}

- (IBAction)degreeHasChanged:(id)sender forEvent:(UIEvent *)event {
    UISegmentedControl *control = (UISegmentedControl*) sender;
    
    if (control.selectedSegmentIndex == 0)
    {
        // Celsius
        fahrenheit = NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"fahrenheit"];
        [self.degrees setText:@"°C"];
        temperatureValue = (temperatureValue - 32.0f) * 5.0f / 9.0f;
    }
    else
    {
        // Fahrenheit
        fahrenheit = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fahrenheit"];
        [self.degrees setText:@"°F"];
        temperatureValue = temperatureValue * 9.0f / 5.0f + 32.0f;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (connectedPeripheral != nil)
    {
        [self.temperature setText:[NSString stringWithFormat:@"%.2f", temperatureValue]];
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
        controller.filterUUID = htsServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"-HTM (Health Thermometer Monitor) profile allows you to connect to your Health Thermometer sensor.\n\n-It shows you the temperature value in Celisius and Fahrenheit units.\n\n-Default temperature unit is Celsius but you can set up unit in the iPhone Settings."];
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
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[htsServiceUUID, batteryServiceUUID]];
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
        
        [self clearUI];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void) clearUI
{
    [deviceName setText:@"DEFAULT HTM"];
    battery.tag = 0;
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    [self.temperature setText:@"-"];
    [self.timestamp setText:@""];
    [self.type setText:@""];
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
        if ([service.UUID isEqual:htsServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[htsMeasurementCharacteristicUUID] forService:service];
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
    if ([service.UUID isEqual:htsServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:htsMeasurementCharacteristicUUID])
            {
                // Enable notification on data characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                break;
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
            uint8_t batteryLevel = [CharacteristicReader readUInt8Value:&array];
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
        else if ([characteristic.UUID isEqual:htsMeasurementCharacteristicUUID])
        {
            int flags = [CharacteristicReader readUInt8Value:&array];
            BOOL tempInFahrenheit = (flags & 0x01) > 0;
            BOOL timestampPresent = (flags & 0x02) > 0;
            BOOL typePresent = (flags & 0x04) > 0;
            
            float tempValue = [CharacteristicReader readFloatValue:&array];
            if (!tempInFahrenheit && fahrenheit)
                tempValue = tempValue * 9.0f / 5.0f + 32.0f;
            if (tempInFahrenheit && !fahrenheit)
                tempValue = (tempValue - 32.0f) * 5.0f / 9.0f;
            temperatureValue = tempValue;
            self.temperature.text = [NSString stringWithFormat:@"%.2f", tempValue];
            
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
                self.timestamp.text = @"Date n/a";
            }
            
            /* temperature type */
            if (typePresent)
            {
                uint8_t type = [CharacteristicReader readUInt8Value:&array];
                NSString* location = nil;
                
                switch (type)
                {
                    case 0x01:
                        location = @"Armpit";
                        break;
                    case 0x02:
                        location = @"Body - general";
                        break;
                    case 0x03:
                        location = @"Ear";
                        break;
                    case 0x04:
                        location = @"Finger";
                        break;
                    case 0x05:
                        location = @"Gastro-intenstinal Tract";
                        break;
                    case 0x06:
                        location = @"Mouth";
                        break;
                    case 0x07:
                        location = @"Rectum";
                        break;
                    case 0x08:
                        location = @"Toe";
                        break;
                    case 0x09:
                        location = @"Tympanum - ear drum";
                        break;
                    default:
                        location = @"Unknown";
                        break;
                }
                if (location)
                {
                    self.type.text = [NSString stringWithFormat:@"Location: %@", location];
                }
            }
            else
            {
                self.type.text = @"Location: n/a";
            }
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                UILocalNotification *notification = [[UILocalNotification alloc]init];
                notification.alertAction = @"Show";
                if (fahrenheit)
                {
                    notification.alertBody = [NSString stringWithFormat:@"New temperature reading: %.2f°F", tempValue];
                }
                else
                {
                    notification.alertBody = [NSString stringWithFormat:@"New temperature reading: %.2f°C", tempValue];
                }
                notification.hasAction = YES;
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
                notification.timeZone = [NSTimeZone  defaultTimeZone];
                notification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
            }
        }
    });
}

@end
