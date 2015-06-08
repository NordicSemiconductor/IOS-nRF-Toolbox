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

#import "StubViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"

@interface StubViewController () {
    CBUUID *htsServiceUUID;
    CBUUID *htsMeasurementCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@end

@implementation StubViewController
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
        htsServiceUUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
        htsMeasurementCharacteristicUUID = [CBUUID UUIDWithString:htsMeasurementCharacteristicUUIDString];
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
        controller.filterUUID = htsServiceUUID;
        controller.delegate = self;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
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
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void) clearUI
{
    // TODO
}


@end
