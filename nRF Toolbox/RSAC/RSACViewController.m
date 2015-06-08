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

#import "RSACViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "CharacteristicReader.h"
#import "HelpViewController.h"

@interface RSACViewController () {
    /*!
     * Number of steps counted during the current connection session. Calculated based on cadence and time intervals
     */
    uint32_t stepsNumber;
    /*!
     * Number of steps counted during the current connection session. Calculated based on cadence and time intervals
     */
    uint8_t cadenceValue;
    /*!
     * The last strip length obtained from the device
     */
    uint8_t stripLength;
    /*!
     * Trip distance, since connection established, in [cm]. Calculated with each step. If stride length is not present it equals UINT32_MAX.
     */
    uint32_t tripDistance;
    
    CBUUID *rscServiceUUID;
    CBUUID *rscMeasurementCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
    BOOL isBackButtonPressed;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

/*!
 * The timer is used to periodically update strides number
 */
@property (strong, nonatomic) NSTimer *timer;

- (void)timerFireMethod:(NSTimer *)_timer;
- (void)appDidEnterBackground:(NSNotification *)_notification;
- (void)appDidBecomeActiveBackground:(NSNotification *)_notification;

@end

@implementation RSACViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize connectedPeripheral;
@synthesize timer;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        stepsNumber = 0;
        tripDistance = UINT32_MAX;
        rscServiceUUID = [CBUUID UUIDWithString:rscServiceUUIDString];
        rscMeasurementCharacteristicUUID = [CBUUID UUIDWithString:rscMeasurementCharacteristicUUIDString];
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Adjust the background to fill the phone space
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
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-170.0f, 0.0f), (float)(-M_PI / 2));
    isBackButtonPressed = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (connectedPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isBackButtonPressed = YES;
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ peripheral. It will collect data also in background.",connectedPeripheral.name]];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
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
        controller.filterUUID = rscServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [AppUtilities getRSACHelpText];
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
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[rscServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
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
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected",peripheral.name]];
        }
        connectedPeripheral = nil;
        [self clearUI];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void) clearUI
{
    stepsNumber = 0;
    tripDistance = UINT32_MAX;
    cadenceValue = 0;
    timer = nil;
    [deviceName setText:@"DEFAULT RSC"];
    battery.tag = 0;
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    [self.speed setText:@"-"];
    [self.cadence setText:@"-"];
    [self.distance setText:@"-"];
    [self.distanceUnit setText:@"m"];
    [self.totalDistance setText:@"-"];
    [self.strides setText:@"-"];
    [self.activity setText:@"n/a"];
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
        if ([service.UUID isEqual:rscServiceUUID])
        {
            [connectedPeripheral discoverCharacteristics:@[rscMeasurementCharacteristicUUID] forService:service];
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
    if ([service.UUID isEqual:rscServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:rscMeasurementCharacteristicUUID])
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
        else if ([characteristic.UUID isEqual:rscMeasurementCharacteristicUUID])
        {
            UInt8 flags = [CharacteristicReader readUInt8Value:&array];
            BOOL strideLengthPresent = (flags & 0x01) > 0;
            BOOL totalDistancePresent = (flags & 0x02) > 0;
            BOOL walking = (flags & 0x04) > 0;
            if (walking)
            {
                [self.activity setText:@"WALKING"];
            }
            else
            {
                [self.activity setText:@"RUNNING"];
            }
            
            float speedValue = [CharacteristicReader readUInt16Value:&array] / 256.0f * 3.6f;
            self.speed.text = [NSString stringWithFormat:@"%.1f", speedValue];
            
            cadenceValue = [CharacteristicReader readUInt8Value:&array];
            self.cadence.text = [NSString stringWithFormat:@"%d", cadenceValue];
            
            // If user started to walk, we have to initialize the timer that will increase strides counter
            if (cadenceValue > 0 && timer == nil)
            {
                self.strides.text = [NSString stringWithFormat:@"%d", stepsNumber];
                
                float timeInterval = 65.0f / cadenceValue; // 60 second + 5 for calibration
                timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
            }
            
            if (totalDistancePresent)
            {
                float distanceValue = [CharacteristicReader readUInt32Value:&array]; // [dm]
                if (distanceValue < 10000) // 1 km in dm
                {
                    self.totalDistance.text = [NSString stringWithFormat:@"%.0f", distanceValue / 10];
                    self.totalDistanceUnit.text = @"m";
                }
                else
                {
                    self.totalDistance.text = [NSString stringWithFormat:@"%.2f", distanceValue / 10000];
                    self.totalDistanceUnit.text = @"km";
                }
            }
            else
            {
                [self.totalDistance setText:@"n/a"];
            }
            
            if (strideLengthPresent)
            {
                stripLength = [CharacteristicReader readUInt16Value:&array]; // [cm]
            }
        }
    });
}

-(void)timerFireMethod:(NSTimer *)_timer
{
    // Here we will update the stride count.
    // If a device has been disconnected, abort. There is nothing to do.
    if (connectedPeripheral == nil)
        return;
    
    // If we are connected, increase the strides counter and display it
    stepsNumber++;
    self.strides.text = [NSString stringWithFormat:@"%d", stepsNumber];
    
    // If stride length has been set, calculate the trip distance
    if (stripLength > 0)
    {
        tripDistance += stripLength;
        if (tripDistance < 100000) // 1 km in cm
        {
            self.distance.text = [NSString stringWithFormat:@"%.0f", tripDistance / 100.0f];
            self.distanceUnit.text = @"m";
        }
        else
        {
            self.distance.text = [NSString stringWithFormat:@"%.2f", tripDistance / 100000.0f];
            self.distanceUnit.text = @"km";
        }
    }
    else
    {
        if (tripDistance == 0)
        {
            self.distance.text = @"n/a";
        }
    }
    
    // If cadence is greater than 0 we have to reschedule the timer with new time interval
    if (cadenceValue > 0)
    {
        float timeInterval = 65.0f / cadenceValue; // 60 second + 5 for calibration
        timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
    }
    else
    {
        timer = nil;
    }
}

@end
