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

#import "CSCViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "HelpViewController.h"

@interface CSCViewController () {
    CBUUID *cscServiceUUID;
    CBUUID *cscMeasurementCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
    int oldWheelRevolution, oldCrankRevolution;
    double travelDistance, oldWheelEventTime, totalTravelDistance, oldCrankEventTime;
    double wheelCircumference;
    BOOL isBackButtonPressed;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *cyclePeripheral;

@end

@implementation CSCViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize cyclePeripheral;
@synthesize speed;
@synthesize cadence;
@synthesize distance;
@synthesize totalDistance;
@synthesize wheelToCrankRatio;

const uint8_t WHEEL_REVOLUTION_FLAG = 0x01;
const uint8_t CRANK_REVOLUTION_FLAG = 0x02;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        cscServiceUUID = [CBUUID UUIDWithString:cscServiceUUIDString];
        cscMeasurementCharacteristicUUID = [CBUUID UUIDWithString:cscMeasurementCharacteristicUUIDString];
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
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-150.0f, 0.0f), (float)(-M_PI / 2));
    oldWheelEventTime = 0.0;
    oldWheelRevolution = 0;
    travelDistance = 0.0;
    totalTravelDistance = 0.0;
    oldCrankEventTime = 0;
    oldCrankRevolution = 0;
    
    wheelCircumference = [[[NSUserDefaults standardUserDefaults] valueForKey:@"key_diameter"] doubleValue];
    NSLog(@"circumference: %f",wheelCircumference);
    isBackButtonPressed = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ peripheral. It will collect data also in background.",self.cyclePeripheral.name]];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (cyclePeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:cyclePeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isBackButtonPressed = YES;
}

- (IBAction)connectOrDisconnectClicked {
    if (cyclePeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:cyclePeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || cyclePeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = cscServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [AppUtilities getCSCHelpText];
    }
}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    cyclePeripheral = peripheral;
    cyclePeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:cyclePeripheral options:options];
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
    [cyclePeripheral discoverServices:@[cscServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
        cyclePeripheral = nil;        
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ is disconnected",peripheral.name]];
        }
        cyclePeripheral = nil;
        [self clearUI];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    if (!error) {
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:cscServiceUUID])
            {
                [cyclePeripheral discoverCharacteristics:nil forService:service];
            }
            else if ([service.UUID isEqual:batteryServiceUUID])
            {
                [cyclePeripheral discoverCharacteristics:nil forService:service];
            }
        }
    } else {
        NSLog(@"error in discovering services on device: %@",cyclePeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:cscServiceUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:cscMeasurementCharacteristicUUID]) {
                    [cyclePeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
            }
        }
        else if ([service.UUID isEqual:batteryServiceUUID]) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
                    [cyclePeripheral readValueForCharacteristic:characteristic];
                }
            }
            
        }
        
    } else {
        NSLog(@"error in discovering characteristic on device: %@",cyclePeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            NSLog(@"received update from CSC: %@, UUID: %@",characteristic.value,characteristic.UUID);
            if ([characteristic.UUID isEqual:cscMeasurementCharacteristicUUID]) {
                [self decodeCSCData:characteristic.value];
            }
            else if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
                const uint8_t *array = [characteristic.value bytes];
                uint8_t batteryLevel = array[0];
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
        }
        else {
            NSLog(@"error in update CSC value");
        }
    });
}

-(void)decodeCSCData:(NSData *)data
{
    NSLog(@"decodeCSCData");
    const uint8_t *value = [data bytes];
    double wheelRevDiff,crankRevDiff;
    wheelRevDiff = crankRevDiff = 0.0;
    double ratio = 0.0;
    uint8_t flag = value[0];
    
    if ((flag & WHEEL_REVOLUTION_FLAG) == 1) {
        wheelRevDiff = [self processWheelData:data];
        if ((flag & 0x02) == 2)  {
            crankRevDiff = [self processCrankData:data crankRevolutionIndex:7];
            if (crankRevDiff > 0) {
                ratio = wheelRevDiff/crankRevDiff;
                wheelToCrankRatio.text = [NSString stringWithFormat:@"%.2f",ratio];
            }
        }
    }
    else {
        if ((flag & CRANK_REVOLUTION_FLAG) == 2)  {
            [self processCrankData:data crankRevolutionIndex:1];
        }
    }
}

-(double) processWheelData:(NSData *)data
{
    /* wheel Revolution Data Present
     * 4 bytes (1 to 4) uint32 are Cummulative Wheel Revolutions
     * next 2 bytes (5 to 6) uint16 are Last Wheel Event Time in seconds and
     * Last Wheel Event Time unit has resolution of 1/1024 seconds
     */
    
    uint32_t wheelRevolution = 0;
    double wheelEventTime = 0.0;
    double wheelRevolutionDiff = 0.0;
    double wheelEventTimeDiff = 0.0;
    double travelSpeed = 0.0;
    const uint8_t *value = [data bytes];
    
    wheelRevolution = CFSwapInt32LittleToHost(*(uint32_t *)(&value[1]));
    wheelEventTime = (CFSwapInt16LittleToHost(*(uint16_t *)(&value[5])))+1;
    if (oldWheelRevolution != 0) {
        wheelRevolutionDiff = wheelRevolution - oldWheelRevolution;
        travelDistance = travelDistance + ((wheelRevolutionDiff * wheelCircumference) / 1000.0);
        totalTravelDistance = ((wheelRevolution * wheelCircumference) / 1000.0);
    }
    if (oldWheelEventTime != 0) {
        wheelEventTimeDiff = ((wheelEventTime - oldWheelEventTime));
    }
    if (wheelEventTimeDiff > 0) {
        wheelEventTimeDiff = wheelEventTimeDiff / 1024.0;
        //convert speed from m/s to km/h by multiplying 3.6
        travelSpeed = (((wheelRevolutionDiff * wheelCircumference)/wheelEventTimeDiff)*3.6);
        NSLog(@"Travel Speed in km/h: %f",travelSpeed);
        speed.text = [NSString stringWithFormat:@"%.2f",travelSpeed];
        distance.text = [NSString stringWithFormat:@"%.2f",travelDistance];
        totalDistance.text = [NSString stringWithFormat:@"%.2f",totalTravelDistance];
    }
    
    oldWheelRevolution = wheelRevolution;
    oldWheelEventTime = wheelEventTime;
    return wheelRevolutionDiff;
}

-(double) processCrankData:(NSData *)data crankRevolutionIndex:(int)index
{
    /* Crank Revolution data present
     * if Wheel Revolution data present then
     * Crank Revolution data starts from index 7 else from index 1
     * 2 bytes uint16 are Cummulative Crank Revolutions
     * next 2 bytes uint16 are Last Crank Event time in seconds and
     * Last Crank Event Time unit has a resolution of 1/1024 seconds
     */
    
    double crankEventTime = 0.0;
    double crankRevolutionDiff = 0.0;
    double crankEventTimeDiff = 0.0;
    int crankRevolution = 0;
    int travelCadence = 0;
    const uint8_t *value = [data bytes];
    
    crankRevolution = CFSwapInt16LittleToHost(*(uint16_t *)(&value[index]));
    crankEventTime = (CFSwapInt16LittleToHost(*(uint16_t *)(&value[index+2])) + 1);
    if (oldCrankEventTime != 0) {
        crankEventTimeDiff = crankEventTime - oldCrankEventTime;
    }
    if (oldCrankRevolution != 0) {
        crankRevolutionDiff = crankRevolution - oldCrankRevolution;
    }
    if (crankEventTimeDiff > 0) {
        crankEventTimeDiff = crankEventTimeDiff / 1024.0;
        travelCadence = ((crankRevolutionDiff / crankEventTimeDiff) * 60);
    }
    oldCrankRevolution = crankRevolution;
    oldCrankEventTime = crankEventTime;
    cadence.text = [NSString stringWithFormat:@"%d",travelCadence];
    return crankRevolutionDiff;
}

- (void) clearUI
{
    [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    deviceName.text = @"DEFAULT CSC";
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    battery.tag = 0;
    speed.text = @"-";
    cadence.text = @"-";
    distance.text = @"-";
    totalDistance.text = @"-";
    wheelToCrankRatio.text = @"-";
    oldWheelEventTime = 0.0;
    oldWheelRevolution = 0.0;
    oldCrankEventTime = 0.0;
    oldCrankRevolution = 0.0;
    travelDistance = 0;
    totalTravelDistance = 0;
    
}


@end