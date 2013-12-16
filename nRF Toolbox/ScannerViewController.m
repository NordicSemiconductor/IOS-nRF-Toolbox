//
//  ScannerViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ScannerViewController.h"
#import "ScannedPeripheral.h"
#import "Constants.h"

@interface ScannerViewController () {
    /*!
     * List of the peripherals shown on the table view. Peripheral are added to this list when it's discovered.
     * Only peripherals with bridgeServiceUUID in the advertisement packets are being displayed.
     */
    NSMutableArray *peripherals;
    /*!
     * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
     * after navigating back to ViewController.
     */
    CBPeripheral *connectedPeripheral;
}

@end

@implementation ScannerViewController
@synthesize bluetoothManager;
@synthesize devicesTable;

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
	// Do any additional setup after loading the view.
    peripherals = [NSMutableArray arrayWithCapacity:8];
    devicesTable.delegate = self;
    devicesTable.dataSource = self;
    
    dispatch_queue_t centralQueue = dispatch_queue_create("no.nordicsemi.ios.nrftoolbox", DISPATCH_QUEUE_SERIAL);
    bluetoothManager = [[CBCentralManager alloc]initWithDelegate:self queue:centralQueue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didCancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Central Manager delegate methods

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self scanForPeripherals:YES];
    }
}

/*!
 * @brief Starts scanning for peripherals with bridgeServiceUUID
 * @param enable If YES, this method will enable scanning for bridge devices, if NO it will stop scanning
 * @return 0 if success, -1 if Bluetooth Manager is not in CBCentralManagerStatePoweredOn state.
 */
- (int) scanForPeripherals:(BOOL)enable
{
    if (bluetoothManager.state != CBCentralManagerStatePoweredOn)
    {
        return -1;
    }
    
    if (enable)
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        [bluetoothManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:rscServiceUUID] ] options:options];
    } else
    {
        [bluetoothManager stopScan];
    }
    return 0;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        // Add the sensor to the list and reload deta set
        ScannedPeripheral* sensor = [ScannedPeripheral initWithPeripheral:peripheral rssi:RSSI.intValue];
        if (![peripherals containsObject:sensor])
        {
            [peripherals addObject:sensor];
        }
        else
        {
            sensor = [peripherals objectAtIndex:[peripherals indexOfObject:sensor]];
            sensor.RSSI = RSSI.intValue;
        }
        [devicesTable reloadData];
    });
}

#pragma mark Table View delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [bluetoothManager stopScan];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Call delegate method
    [self.delegate centralManager:bluetoothManager didPeripheralSelected:[[peripherals objectAtIndex:indexPath.row] peripheral]];
}

#pragma mark Table View Data Source delegate methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return peripherals.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // Update sensor name
    ScannedPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = [[peripheral peripheral] name];
    
    // Update RSSI indicator
    int RSSI = peripheral.RSSI;
    UIImage* image;
    if (RSSI < -90) {
        image = [UIImage imageNamed: @"Signal_0"];
    }
    else if (RSSI < -70)
    {
        image = [UIImage imageNamed: @"Signal_1"];
    }
    else if (RSSI < -50)
    {
        image = [UIImage imageNamed: @"Signal_2"];
    }
    else
    {
        image = [UIImage imageNamed: @"Signal_3"];
    }
    cell.imageView.image = image;
    return cell;
}

@end
