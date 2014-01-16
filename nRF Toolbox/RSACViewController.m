//
//  RSACViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 13/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "RSACViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"

@interface RSACViewController () {
    /*!
     * Number of steps counted during the current connection session. Calculated based on cadence and time intervals
     */
    uint32_t stepsNumber;
    /*!
     * Number of steps counted during the current connection session. Calculated based on cadence and time intervals
     */
    uint8_t cadenceValue;
    
    CBUUID *rscServiceUUID;
    CBUUID *rscMeasurementCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
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
    self.verticalLabel.transform = CGAffineTransformMakeRotation(-M_PI / 2);
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (connectedPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.alertAction = @"Show";
    notification.alertBody = @"You are still connected to Running Speed and Cadence sensor. It will collect data also in background.";
    notification.hasAction = NO;
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.timeZone = [NSTimeZone  defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
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
    [peripheral discoverServices:@[rscServiceUUID, batteryServiceUUID]];
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
    stepsNumber = 0;
    cadenceValue = 0;
    timer = nil;
    [deviceName setText:@"DEFAULT RSC"];
    battery.tag = 0;
    [battery setTitle:@"n/a" forState:UIControlStateNormal];
    [self.speed setText:@"-"];
    [self.cadence setText:@"-"];
    [self.distance setText:@"-"];
    [self.distanceUnit setText:@"m"];
    [self.strideLength setText:@"-"];
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
        else if ([characteristic.UUID isEqual:rscMeasurementCharacteristicUUID])
        {
            int flags = array[0];
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
            
            float speedValue = [self uint16_decode:array + 1] / 256.0f * 3.6f;
            self.speed.text = [NSString stringWithFormat:@"%.1f", speedValue];
            
            cadenceValue = array[3];
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
                float distanceValue = [self uint32_decode:array + 6];
                if (distanceValue < 10000) // 1 km in dm
                {
                    self.distance.text = [NSString stringWithFormat:@"%.0f", distanceValue / 10];
                    self.distanceUnit.text = @"m";
                }
                else
                {
                    self.distance.text = [NSString stringWithFormat:@"%.2f", distanceValue / 10000];
                    self.distance.text = @"km";
                }
            }
            else
            {
                [self.distance setText:@"n/a"];
            }
            
            if (strideLengthPresent)
            {
                int strideLengthValue = [self uint16_decode:array + 4];
                self.strideLength.text = [NSString stringWithFormat:@"%d", strideLengthValue];
            }
            else
            {
                self.strideLength.text = @"n/a";
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
    [self.strides setText:[[NSString alloc] initWithFormat:@"%d", stepsNumber]];
    
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

/**@brief Inline function for decoding a uint16 value.
 *
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 *
 * @return      Decoded value.
 */
- (uint16_t) uint16_decode:(const uint8_t *) p_encoded_data
{
    return ( (((uint16_t)((uint8_t *)p_encoded_data)[0])) |
            (((uint16_t)((uint8_t *)p_encoded_data)[1]) << 8 ));
}

/**@brief Inline function for decoding a uint16 value.
 *
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 *
 * @return      Decoded value.
 */
- (uint32_t) uint32_decode:(const uint8_t *) p_encoded_data
{
    return ( (((uint32_t)((uint8_t *)p_encoded_data)[0])) |
            (((uint32_t)((uint8_t *)p_encoded_data)[1]) << 8) |
            (((uint32_t)((uint8_t *)p_encoded_data)[2]) << 16) |
            (((uint32_t)((uint8_t *)p_encoded_data)[3]) << 24 ));
}


@end
