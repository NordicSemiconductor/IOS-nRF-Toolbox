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

#import <AVFoundation/AVFoundation.h>
#import "ProximityViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "HelpViewController.h"


@interface ProximityViewController () {
    CBUUID *proximityImmediateAlertServiceUUID;
    CBUUID *proximityLinkLossServiceUUID;
    CBUUID *proximityAlertLevelCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
    BOOL isImmidiateAlertOn, isBackButtonPressed;;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *proximityPeripheral;
@property (strong, nonatomic)CBPeripheralManager *peripheralManager;
@property (strong, nonatomic)CBCharacteristic *immidiateAlertCharacteristic;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation ProximityViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize proximityPeripheral;
@synthesize findMeButton;
@synthesize lockImage;
@synthesize audioPlayer;



-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        proximityImmediateAlertServiceUUID = [CBUUID UUIDWithString:proximityImmediateAlertServiceUUIDString];
        proximityLinkLossServiceUUID = [CBUUID UUIDWithString:proximityLinkLossServiceUUIDString];
        proximityAlertLevelCharacteristicUUID = [CBUUID UUIDWithString:proximityAlertLevelCharacteristicUUIDString];
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
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-110.0f, 0.0f), (float)(-M_PI / 2));
    [self initGattServer];
    self.immidiateAlertCharacteristic = nil;
    isImmidiateAlertOn = NO;
    isBackButtonPressed = NO;
    [self initSound];
}

-(void) initSound
{
    NSError *error  = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"high" ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@",
              [error localizedDescription]);
    } else {        
        [audioPlayer prepareToPlay];
    }
}


-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSString *message = [NSString stringWithFormat:@"You are still connected to %@",proximityPeripheral.name];
    [AppUtilities showBackgroundNotification:message];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (IBAction)connectOrDisconnectClicked {
    NSLog(@"connect button pressed");
    if (proximityPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:proximityPeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || proximityPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = proximityLinkLossServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [AppUtilities getProximityHelpText];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (proximityPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:proximityPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isBackButtonPressed = YES;
}


- (IBAction)findMeButtonClicked
{
    NSLog(@"FindMeButtonPressed");
    if (self.immidiateAlertCharacteristic) {
        if (isImmidiateAlertOn) {
            [self immidiateAlertOff];
        }
        else {
            [self immidiateAlertOn];
        }
    }
}

-(void) enableFindMeButton
{
    findMeButton.enabled = YES;
    [findMeButton setBackgroundColor:[UIColor blackColor]];
    [findMeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) disableFindButton
{
    findMeButton.enabled = NO;
    [findMeButton setBackgroundColor:[UIColor lightGrayColor]];
    [findMeButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
}


-(void)initGattServer
{
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

-(void)addServices
{
    NSLog(@"addServices");
    CBMutableService *service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:@"1802"] primary:YES];
    service.characteristics = [NSArray arrayWithObject:[self createCharacteristic]];
    [self.peripheralManager addService:service];
    
}

-(CBMutableCharacteristic *)createCharacteristic
{
    NSLog(@"createCharacteristic");
    CBCharacteristicProperties properties = CBCharacteristicPropertyWriteWithoutResponse;
    CBAttributePermissions permissions = CBAttributePermissionsWriteable;
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:@"2A06"] properties:properties value:nil permissions:permissions];
    return characteristic;
    
}

-(void)immidiateAlertOn
{
    if (self.immidiateAlertCharacteristic) {
        NSLog(@"immidiateAlertOn");
        uint8_t val = 2;
        NSData *data = [NSData dataWithBytes:&val length:1];
        [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
        isImmidiateAlertOn = true;
        [findMeButton setTitle:@"SilentMe" forState:UIControlStateNormal];
    }
}

-(void)immidiateAlertOff
{
    if (self.immidiateAlertCharacteristic) {
        NSLog(@"immidiateAlertOff");
        uint8_t val = 0;
        NSData *data = [NSData dataWithBytes:&val length:1];
        [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
        isImmidiateAlertOn = false;
        [findMeButton setTitle:@"FindMe" forState:UIControlStateNormal];
    }
    
}

#pragma mark Playing Sound methods
- (void) stopSound {
    [audioPlayer stop];
}

-(void) playSoundInLoop
{
    audioPlayer.numberOfLoops = -1;
    [audioPlayer play];
}

-(void) playSoundOnce
{
    [audioPlayer play];
}

#pragma mark CBPeripheralManager delegates
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    switch ([peripheral state]) {
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"State is Off");
            break;
            
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"State is on");
            [self addServices];
            break;
            
        default:
            break;
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error in adding service");
    }
    else {
        NSLog(@"service added successfully");
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *attributeRequest = [requests objectAtIndex:0];
    if ([attributeRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
        const uint8_t *data = [attributeRequest.value bytes];
        int alertLevel = data[0];
        NSLog(@"Alert Level is: %d",alertLevel);
        switch (alertLevel) {
            case 0:
                NSLog(@"No alert");
                [self stopSound];
                break;
            case 1:
                NSLog(@"Low alert");
                [self playSoundInLoop];
                break;
            case 2:
                NSLog(@"High alert");
                [self playSoundInLoop];
                
                break;
                
            default:
                break;
        }
        
    }
}


#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    proximityPeripheral = peripheral;
    proximityPeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:proximityPeripheral options:options];
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
        lockImage.highlighted = YES;
        [self enableFindMeButton];
    });
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if ([AppUtilities isApplicationStateInactiveORBackground]) {
        NSString *message = [NSString stringWithFormat:@"%@ is within range!",proximityPeripheral.name];
        [AppUtilities showBackgroundNotification:message];
    }
    
    // Peripheral has connected. Discover required services
    [proximityPeripheral discoverServices:@[proximityLinkLossServiceUUID, proximityImmediateAlertServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        proximityPeripheral = nil;
        [self disableFindButton];
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"%@ is out of range!",proximityPeripheral.name];
        if (error) {
            NSLog(@"error in disconnection or linkloss");
            lockImage.highlighted = NO;
            self.immidiateAlertCharacteristic = nil;
            [self disableFindButton];
            NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
            [bluetoothManager connectPeripheral:proximityPeripheral options:options];
            if ([AppUtilities isApplicationStateInactiveORBackground]) {
                [AppUtilities showBackgroundNotification:message];
            }
            else {
                [AppUtilities showAlert:@"PROXIMITY" alertMessage:message];
            }
            [self playSoundOnce];
            
        }
        else {
                NSLog(@"disconnected");
                [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
                if ([AppUtilities isApplicationStateInactiveORBackground]) {
                    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected",peripheral.name]];
                }
                proximityPeripheral = nil;
                [self disableFindButton];
                [self clearUI];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            
        }
    });
}

#pragma mark CBPeripheral delegates
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices inside %@",peripheral.name);
    for (CBService *service in peripheral.services) {
        NSLog(@"service found: %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
            NSLog(@"Linkloss service is found");
            [proximityPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A06"]] forService:service];
        }
        else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1802"]]) {
            NSLog(@"Immidiate Alert service is found");
            [proximityPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A06"]] forService:service];
        }
        else if ([service.UUID isEqual:batteryServiceUUID])
        {
            NSLog(@"Battery service found");
            [proximityPeripheral discoverCharacteristics:nil forService:service];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
                NSLog(@"Alert level characteristic is found under Linkloss service");
                uint8_t val = 1;
                NSData *data = [NSData dataWithBytes:&val length:1];
                NSLog(@"writing Alert level characteristic");
                [proximityPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    }
    else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1802"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
                NSLog(@"Alert level characteristic is found under Immidiate Alert service");
                self.immidiateAlertCharacteristic = characteristic;
            }
        }
    }
    else if ([service.UUID isEqual:batteryServiceUUID]) {
        
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
                NSLog(@"Battery Level characteristic is found");
                [proximityPeripheral readValueForCharacteristic:characteristic];
            }
        }
        
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
            const uint8_t *array = [characteristic.value bytes];
            uint8_t batteryLevel = array[0];
                NSLog(@"battery value received %d",batteryLevel);
            NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
            [battery setTitle:text forState:UIControlStateDisabled];
            if (battery.tag == 0)
            {
                // If battery level notifications are available, enable them
                if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
                {
                    NSLog(@"battery has notifications");
                    battery.tag = 1; // mark that we have enabled notifications
                    
                    // Enable notification on data characteristic
                    [proximityPeripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else
                {
                    NSLog(@"battery don't have notifications");
                }
            }
        }
        });
    }
    else {
        NSLog(@"error in Battery value");
    }
}

- (void) clearUI
{
    deviceName.text = @"DEFAULT PROXIMITY";
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    battery.tag = 0;
    lockImage.highlighted = NO;
    isImmidiateAlertOn = NO;
    self.immidiateAlertCharacteristic = nil;
}


@end
