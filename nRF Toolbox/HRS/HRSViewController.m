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

#import "HRSViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "CorePlot-CocoaTouch.h"
#import "HelpViewController.h"

@interface HRSViewController ()
{
    NSMutableArray *hrValues;
    int number;
    int plotXMaxRange, plotXMinRange, plotYMaxRange, plotYMinRange;
    int plotXInterval, plotYInterval;
    
    BOOL isBluetoothON;
    BOOL isDeviceConnected;
    BOOL isBackButtonPressed;
    
    CBUUID *HR_Service_UUID;
    CBUUID *HR_Measurement_Characteristic_UUID;
    CBUUID *HR_Location_Characteristic_UUID;
    CBUUID *Battery_Service_UUID;
    CBUUID *Battery_Level_Characteristic_UUID;
    CBUUID *dfuService_UUID;
    CBUUID *dfuControl_Point_Characteristic_UUID;
    CBUUID *dfuPacket_Characteristic_UUID;
}
@property CPTScatterPlot *linePlot;
@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTGraph *graph;

@property (strong, nonatomic) CBPeripheral *hrPeripheral;

@end

@implementation HRSViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize hrValue;
@synthesize hrLocation;
@synthesize hostView;
@synthesize hrPeripheral;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization        
        HR_Service_UUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
        HR_Measurement_Characteristic_UUID = [CBUUID UUIDWithString:hrsHeartRateCharacteristicUUIDString];
        HR_Location_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorLocationCharacteristicUUIDString];
        Battery_Service_UUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        Battery_Level_Characteristic_UUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
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
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-120.0f, 0.0f), (float)(-M_PI / 2));
    
    isBluetoothON = NO;
    isDeviceConnected = NO;
    isBackButtonPressed = NO;
    hrPeripheral = nil;
    
    hrValues = [[NSMutableArray alloc]init];
    number = 0;
    plotXMaxRange = 100;
    plotXMinRange = 0;
    plotYMaxRange = 305;
    plotYMinRange = 0;
    
    plotXInterval = 20;
    plotYInterval = 50;
    
    [self initLinePlot];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
    if (hrPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:hrPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
    isBackButtonPressed = YES;
}

- (IBAction)connectOrDisconnectClicked
{
    if (hrPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:hrPeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || hrPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        NSLog(@"prepareForSegue scan");
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = HR_Service_UUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"prepareForSegue help");
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [AppUtilities getHRSHelpText];
    }
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterBackground");
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ sensor. It will collect data also in background.",self.hrPeripheral.name]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterForeground");
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark HRM Graph methods

-(void)initLinePlot
{
    //Initialize and display Graph (x and y axis lines)
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphView.bounds];
    self.hostView = [[CPTGraphHostingView alloc] initWithFrame:self.graphView.bounds];
    self.hostView.hostedGraph = self.graph;
    [self.graphView addSubview:hostView];
    
    //apply styling to Graph
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph.backgroundColor = nil;
    self.graph.fill = nil;
    self.graph.plotAreaFrame.fill = nil;
    self.graph.plotAreaFrame.plotArea.fill = nil;
    
    //This removes top and right lines of graph
    self.graph.plotAreaFrame.borderLineStyle = nil;
    //This shows x and y axis labels from 0 to 1
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    // set padding for graph from Left and Bottom
    self.graph.paddingBottom = 30;
    self.graph.paddingLeft = 50;
    self.graph.paddingRight = 0;
    self.graph.paddingTop = 0;
    
    //Define x and y axis range
    // x-axis from 0 to 100
    // y-axis from 0 to 300
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotXMinRange)
                                                    length:CPTDecimalFromInt(plotXMaxRange)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    NSNumberFormatter *axisLabelFormatter = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(plotXInterval);
    axisSet.xAxis.minorTicksPerInterval = 4;
    axisSet.xAxis.minorTickLength = 5;
    axisSet.xAxis.majorTickLength = 7;
    axisSet.xAxis.title = @"Time(Seconds)";
    axisSet.xAxis.titleOffset = 25;
    axisSet.xAxis.labelFormatter = axisLabelFormatter;
    
    //Define y-axis properties
    //y-axis intermediate interval = 50;
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromInt(plotYInterval);
    axisSet.yAxis.minorTicksPerInterval = 4;
    axisSet.yAxis.minorTickLength = 5;
    axisSet.yAxis.majorTickLength = 7;
    axisSet.yAxis.title = @"BPM";
    axisSet.yAxis.titleOffset = 30;
    axisSet.yAxis.labelFormatter = axisLabelFormatter;
    
    
    //Define line plot and set line properties
    self.linePlot = [[CPTScatterPlot alloc] init];
    self.linePlot.dataSource = self;
	[self.graph addPlot:self.linePlot toPlotSpace:plotSpace];
    
    //set line plot style
    CPTMutableLineStyle *lineStyle = [self.linePlot.dataLineStyle mutableCopy];
	lineStyle.lineWidth = 2;
	lineStyle.lineColor = [CPTColor blackColor];
	self.linePlot.dataLineStyle = lineStyle;
    
	CPTMutableLineStyle *symbolineStyle = [CPTMutableLineStyle lineStyle];
	symbolineStyle.lineColor = [CPTColor blackColor];
	CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
	symbol.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
	symbol.lineStyle = symbolineStyle;
	symbol.size = CGSizeMake(3.0f, 3.0f);
	self.linePlot.plotSymbol = symbol;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle = [[CPTMutableLineStyle alloc] init];
    gridLineStyle.lineColor = [CPTColor grayColor];
    gridLineStyle.lineWidth = 0.5;
    axisSet.xAxis.majorGridLineStyle = gridLineStyle;
    axisSet.yAxis.majorGridLineStyle = gridLineStyle;
    
    
}

-(void)updatePlotSpace
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:@[self.linePlot]];
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotXMinRange)
                                                    length:CPTDecimalFromInt(plotXMaxRange)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(plotXInterval);
}

-(void)addHRValueToGraph:(int)data
{
    [hrValues addObject:[NSDecimalNumber numberWithInt:data]];
    if ([hrValues count] > plotXMaxRange) {
        plotXMaxRange = plotXMaxRange + plotXMaxRange;
        plotXInterval = plotXInterval + plotXInterval;
        [self updatePlotSpace];
    }
    [self.graph reloadData];
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [hrValues count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedInteger:index];
			break;
			
		case CPTScatterPlotFieldY:
            return [hrValues objectAtIndex:index];
			break;
	}
	return [NSDecimalNumber zero];
}


#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it    
    hrPeripheral = peripheral;
    hrPeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:hrPeripheral options:options];
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
        [hrValues removeAllObjects];
    });
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    //[hrPeripheral discoverServices:@[HR_Service_UUID,Battery_Service_UUID]];
    [hrPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        hrPeripheral = nil;
        
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        hrPeripheral = nil;
        [self clearUI];
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected.",peripheral.name]];
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
        NSLog(@"services discovered %lu",(unsigned long)[peripheral.services count] );
        for (CBService *hrService in peripheral.services) {
            NSLog(@"service discovered: %@",hrService.UUID);
            if ([hrService.UUID isEqual:HR_Service_UUID])
            {
                NSLog(@"HR service found");
                [hrPeripheral discoverCharacteristics:nil forService:hrService];
            }
            else if ([hrService.UUID isEqual:Battery_Service_UUID])
            {
                NSLog(@"Battery service found");
                [hrPeripheral discoverCharacteristics:nil forService:hrService];
            }
            // code to discover DFU Service
            else if ([hrService.UUID isEqual:dfuService_UUID]) {
                NSLog(@"DFU Service is found");
            }

        }
    } else {
        NSLog(@"error in discovering services on device: %@",hrPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:HR_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                    NSLog(@"HR Measurement characteritsic is found");
                    [hrPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
                else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
                    NSLog(@"HR Position characteristic is found");
                    [hrPeripheral readValueForCharacteristic:characteristic];
                }
            }
        }
        else if ([service.UUID isEqual:Battery_Service_UUID]) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:Battery_Level_Characteristic_UUID]) {
                    NSLog(@"Battery Level characteristic is found");
                    [hrPeripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    } else {
        NSLog(@"error in discovering characteristic on device: %@",hrPeripheral.name);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            NSLog(@"received update from HR: %@, UUID: %@",characteristic.value,characteristic.UUID);
            if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                NSLog(@"HRM value: %@",characteristic.value);
                [self addHRValueToGraph:[self decodeHRValue:characteristic.value]];
                hrValue.text = [NSString stringWithFormat:@"%d",[self decodeHRValue:characteristic.value]];
            }
            else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
                hrLocation.text = [self decodeHRLocation:characteristic.value];
            }
            else if ([characteristic.UUID isEqual:Battery_Level_Characteristic_UUID]) {
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
            NSLog(@"error in update HRM value");
        }
    });
}

-(int) decodeHRValue:(NSData *)data
{
    const uint8_t *value = [data bytes];
    int bpmValue = 0;
    if ((value[0] & 0x01) == 0) {
        NSLog(@"8 bit HR Value");
        bpmValue = value[1];
    }
    else {
        NSLog(@"16 bit HR Value");
        bpmValue = CFSwapInt16LittleToHost(*(uint16_t *)(&value[1]));
    }
    NSLog(@"BPM: %d",bpmValue);
    return bpmValue;
}

-(NSString *) decodeHRLocation:(NSData *)data
{
    const uint8_t *location = [data bytes];
    NSString *hrmLocation;
    switch (location[0]) {
        case 0:
            hrmLocation = @"Other";
            break;
        case 1:
            hrmLocation = @"Chest";
            break;
        case 2:
            hrmLocation = @"Wrist";
            break;
        case 3:
            hrmLocation = @"Finger";
            break;
        case 4:
            hrmLocation = @"Hand";
            break;
        case 5:
            hrmLocation = @"Ear Lobe";
            break;
        case 6:
            hrmLocation = @"Foot";
            break;
        default:
            hrmLocation = @"Invalid";
            break;
    }
    NSLog(@"HRM location is %@",hrmLocation);
    return hrmLocation;
}

- (void) clearUI
{
    deviceName.text = @"DEFAULT HRM";
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    battery.tag = 0;
    hrLocation.text = @"n/a";
    hrValue.text = @"-";
}

@end
