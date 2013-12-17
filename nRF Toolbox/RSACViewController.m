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
    CBPeripheral* connectedPeripheral;
}

@end

@implementation RSACViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;

@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (IBAction)connectOrDisconnectClicked {
    if (connectedPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:connectedPeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"scan"])
    {
        return connectedPeripheral == nil;
    }
    else
    {
        return YES;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
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
    [bluetoothManager connectPeripheral:peripheral options:nil];
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
    
    // Peripheral has connected. Discover required services
    connectedPeripheral = peripheral;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:rscServiceUUID], [CBUUID UUIDWithString:batteryServiceUUID]]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        [deviceName setText:@"DEFAULT RSC"];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [battery setTitle:@"n/a" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [deviceName setText:@"DEFAULT RSC"];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [battery setTitle:@"n/a" forState:UIControlStateNormal];
        connectedPeripheral = nil;
        
        [self clearUI];
    });
}

- (void) clearUI
{
    [self.speed setText:@"-"];
    [self.cadence setText:@"-"];
    [self.distance setText:@"-"];
    [self.distanceUnit setText:@"m"];
    [self.strideLength setText:@"-"];
    [self.activity setText:@"n/a"];
}

#pragma mark Peripheral delegate methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        //progressLabel.text = @"Error occured";
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:rscServiceUUID]])
        {
            [connectedPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:rscMeasurementCharacteristicUUID]] forService:service];
        }
        else if ([service.UUID isEqual:[CBUUID UUIDWithString:batteryServiceUUID]])
        {
            [connectedPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:batteryLevelCharacteristicUUID]] forService:service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Characteristics for one of those services has been found
    if ([service.UUID isEqual:[CBUUID UUIDWithString:rscServiceUUID]])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:rscMeasurementCharacteristicUUID]])
            {
                // Enable notification on data characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                break;
            }
        }
    } else if ([service.UUID isEqual:[CBUUID UUIDWithString:batteryServiceUUID]])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:batteryLevelCharacteristicUUID]])
            {
                // If battery level notifications are available, enable them
                if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
                {
                    // Enable notification on data characteristic
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else
                {
                    [peripheral readValueForCharacteristic:characteristic];
                }
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
    
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:batteryLevelCharacteristicUUID]])
        {
            int batteryLevel = array[0];
            NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
            [battery setTitle:text forState:UIControlStateNormal];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:rscMeasurementCharacteristicUUID]])
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
            [self.speed setText:[[NSString alloc] initWithFormat:@"%.1f", speedValue]];
            
            int cadenceValue = array[3];
            [self.cadence setText:[[NSString alloc] initWithFormat:@"%d", cadenceValue]];
            
            if (totalDistancePresent)
            {
                float distanceValue = [self uint32_decode:array + 6];
                if (distanceValue < 10000) // 1 km in dm
                {
                    [self.distance setText:[[NSString alloc] initWithFormat:@"%.0f", distanceValue / 10]];
                    [self.distanceUnit setText:@"m"];
                }
                else
                {
                    [self.distance setText:[[NSString alloc] initWithFormat:@"%.2f", distanceValue / 10000]];
                    [self.distanceUnit setText:@"km"];
                }
            }
            else
            {
                [self.distance setText:@"n/a"];
            }
            
            if (strideLengthPresent)
            {
                int strideLengthValue = [self uint16_decode:array + 4];
                [self.strideLength setText:[[NSString alloc] initWithFormat:@"%d", strideLengthValue]];
            }
            else
            {
                [self.strideLength setText:@"n/a"];
            }
        }
    });
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
