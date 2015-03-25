//
//  UARTViewController.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 17/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "UARTViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "HelpViewController.h"

@interface UARTViewController ()
{
    CBUUID *UART_Service_UUID;
    CBUUID *UART_RX_Characteristic_UUID;
    CBUUID *UART_TX_Characteristic_UUID;
}

@end

@implementation UARTViewController

@synthesize bluetoothManager;
@synthesize uartPeripheral;
@synthesize connectButton;
@synthesize deviceName;
@synthesize uartRXCharacteristic;

bool isAppInBackground = NO;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        UART_Service_UUID = [CBUUID UUIDWithString:uartServiceUUIDString];
        UART_TX_Characteristic_UUID = [CBUUID UUIDWithString:uartTXCharacteristicUUIDString];
        UART_RX_Characteristic_UUID = [CBUUID UUIDWithString:uartRXCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    // Do any additional setup after loading the view.
    
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-20.0f, 0.0f), (float)(-M_PI / 2));
    self.displayText.delegate = self;
    self.displayText.dataSource = self;
    self.uartDisplayText = [[NSMutableArray alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || uartPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        NSLog(@"prepareForSegue scan");
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = UART_Service_UUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"prepareForSegue help");
        //isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"-UART profile allows you to connect to your UART sensor.\n\n-You can send and receive short messages of 20 characters in total."];
    }
}

-(NSString *)showCurrentTime
{
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [outputFormatter stringFromDate:now];
    return timeString;
}

-(void)writeValueOnRX:(NSString *)value
{
    NSString *text;
    if (value.length != 0) {
        if (value.length > 20) {
            text = [value substringToIndex:20];
        }
        else {
            text = value;
        }
        [self.uartPeripheral writeValue:[text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:uartRXCharacteristic type:CBCharacteristicWriteWithoutResponse];
        [self displayOnTableView:[NSString stringWithFormat:@"RX: %@",text]];
    }
}

-(void)displayOnTableView:(NSString *)text
{
    [self.uartDisplayText addObject:[NSString stringWithFormat:@"[%@] %@",[self showCurrentTime],text]];
    NSLog(@"Number of Strings: %lu",(unsigned long)[self.uartDisplayText count]);
    [self.displayText reloadData];
    [self scrollDisplayViewDown];
    [self showCurrentTime];
}

-(void)scrollDisplayViewDown
{
    NSLog(@"scrollDisplayViewDown");
    [self.displayText scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.uartDisplayText count]-1 inSection:0]
                                 atScrollPosition:UITableViewScrollPositionBottom
                                         animated:YES];
}

#pragma mark - TextField editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldBeginEditing");
    if (uartPeripheral) {
        return YES;
    }
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn");
    [self.uartRXText resignFirstResponder];
    [self writeValueOnRX:self.uartRXText.text];
    self.uartRXText.text = @"";
    return YES;
}

#pragma mark - Tableview delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.uartDisplayText count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"uartCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"uartCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.font  = [ UIFont fontWithName: @"Arial" size: 12.0 ];
    cell.textLabel.text = [self.uartDisplayText objectAtIndex:indexPath.row];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 20.0;
}


#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    uartPeripheral = peripheral;
    uartPeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:uartPeripheral options:options];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    [uartPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [deviceName setText:@"DEFAULT UART"];
        uartPeripheral = nil;
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [deviceName setText:@"DEFAULT UART"];
        uartPeripheral = nil;
        if (isAppInBackground) {
            [self showBackgroundNotification:[NSString stringWithFormat:@"%@ sensor is disconnected",peripheral.name]];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        
    });
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    if (!error) {
        NSLog(@"services discovered %d",[peripheral.services count] );
        for (CBService *uartService in peripheral.services) {
            NSLog(@"service discovered: %@",uartService.UUID);
            if ([uartService.UUID isEqual:UART_Service_UUID])
            {
                NSLog(@"UART service found");
                [uartPeripheral discoverCharacteristics:nil forService:uartService];
            }
        }
    } else {
        NSLog(@"error in discovering services on device: %@",uartPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:UART_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:UART_TX_Characteristic_UUID]) {
                    NSLog(@"UART TX characteritsic is found");
                    [uartPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
                else if ([characteristic.UUID isEqual:UART_RX_Characteristic_UUID]) {
                    NSLog(@"UART RX characteristic is found");
                    uartRXCharacteristic = characteristic;
                }
            }
        }
        
    } else {
        NSLog(@"error in discovering characteristic on device: %@",uartPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            NSLog(@"received update from UART: %@, UUID: %@",characteristic.value,characteristic.UUID);
            if (characteristic.value.length != 0) {
                NSString* text = [NSString stringWithUTF8String:[characteristic.value bytes]];
                [self displayOnTableView:[NSString stringWithFormat:@"TX: %@",text]];
            }
        }
        else {
            NSLog(@"error in update UART value");
        }
    });
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterBackground");
    isAppInBackground = YES;
    [self showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ sensor.",self.uartPeripheral.name]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    NSLog(@"appDidBecomeActiveBackground");
    isAppInBackground = NO;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

-(void)showBackgroundNotification:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.alertAction = @"Show";
    notification.alertBody = message;
    notification.hasAction = NO;
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.timeZone = [NSTimeZone  defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

- (IBAction)connectOrDisconnectClicked:(UIButton *)sender {
    if (uartPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:uartPeripheral];
    }
}
@end
