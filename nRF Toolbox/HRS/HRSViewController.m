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

@interface HRSViewController ()
{
    NSMutableArray *hrValues;
    NSMutableArray *xValues;
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
}
@property CPTScatterPlot *linePlot;
@property (nonatomic, strong) CPTGraph *graph;

@property (strong, nonatomic) CBPeripheral *hrPeripheral;
- (IBAction)aboutButtonClicked:(id)sender;

@end

@implementation HRSViewController
@synthesize bluetoothManager;
@synthesize verticalLabel;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize hrValue;
@synthesize hrLocation;
@synthesize graphView;
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
    
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-120.0f, 0.0f), (float)(-M_PI / 2));
    
    isBluetoothON = NO;
    isDeviceConnected = NO;
    isBackButtonPressed = NO;
    hrPeripheral = nil;
    
    hrValues = [[NSMutableArray alloc]init];
    xValues  = [[NSMutableArray alloc]init];
    
    [self initLinePlot];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (hrPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:hrPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isBackButtonPressed = YES;
}

- (IBAction)aboutButtonClicked:(id)sender {
    [self showAbout:[AppUtilities getHRSHelpText]];
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
        // Set this contoller as scanner delegate
        UINavigationController *nc = segue.destinationViewController;
        ScannerViewController *controller = (ScannerViewController *)nc.childViewControllerForStatusBarHidden;
        controller.filterUUID = HR_Service_UUID;
        controller.delegate = self;
    }
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ sensor. It will collect data also in background.",self.hrPeripheral.name]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark HRM Graph methods

-(void)initLinePlot
{
    //Initialize and display Graph (x and y axis lines)
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphView.bounds];
    self.graphView.hostedGraph = self.graph;
    
    //apply styling to Graph
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    self.graph.plotAreaFrame.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    
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
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    [self resetPlotRange];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    NSNumberFormatter *axisLabelFormatter = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet.xAxis.majorIntervalLength = [NSNumber numberWithInt:plotXInterval];
    axisSet.xAxis.minorTicksPerInterval = 4;
    axisSet.xAxis.minorTickLength = 5;
    axisSet.xAxis.majorTickLength = 7;
    axisSet.xAxis.title = @"Time (s)";
    axisSet.xAxis.titleOffset = 25;
    axisSet.xAxis.labelFormatter = axisLabelFormatter;
    
    //Define y-axis properties
    //y-axis intermediate interval = 50;
    axisSet.yAxis.majorIntervalLength = [NSNumber numberWithInt:plotYInterval];
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
    
	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPTColor blackColor];
	CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
	symbol.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
	symbol.lineStyle = symbolLineStyle;
	symbol.size = CGSizeMake(3.0f, 3.0f);
	self.linePlot.plotSymbol = symbol;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle = [[CPTMutableLineStyle alloc] init];
    gridLineStyle.lineColor = [CPTColor grayColor];
    gridLineStyle.lineWidth = 0.5;
    axisSet.xAxis.majorGridLineStyle = gridLineStyle;
    axisSet.yAxis.majorGridLineStyle = gridLineStyle;
}

-(void) resetPlotRange
{
    plotXMaxRange = 121;
    plotXMinRange = -1;
    plotYMaxRange = 201;
    plotYMinRange = -1;
    
    plotXInterval = 20;
    plotYInterval = 50;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:plotXMinRange]
                                                    length:[NSNumber numberWithInt:plotXMaxRange]];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:plotYMinRange]
                                                    length:[NSNumber numberWithInt:plotYMaxRange]];
}

-(void)addHRValueToGraph:(int)data
{
    // In this method the new value is added to hrValues array
    [hrValues addObject:[NSDecimalNumber numberWithInt:data]];
    
    // Also, we save the time when the data was received
    // 'Last' and 'previous' values are timestamps of those values. We calculate them to know whether we should automatically scroll the graph
    double previous = [[(NSDecimalNumber*)[xValues lastObject] decimalNumberBySubtracting:(NSDecimalNumber*)[xValues firstObject]] doubleValue];
    [xValues addObject:[HRSViewController longUnixEpoch]];
    double last = [[(NSDecimalNumber*)[xValues lastObject] decimalNumberBySubtracting:(NSDecimalNumber*)[xValues firstObject]] doubleValue];
    
    // Here we calculate the max value visible on the graph
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    double max = plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble;
    
    // If the previous value was on the graph, but the new one is out of it, scroll the graph automatically
    if (last > max && previous <= max)
    {
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:last - plotXMaxRange + 1]
                                                        length:[NSNumber numberWithInt:plotXMaxRange]];
    }
    
    // Rescale Y axis to display higher values
    if (data >= plotYMaxRange)
    {
        while (data >= plotYMaxRange)
        {
            plotYMaxRange += 50;
        }
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:plotYMinRange]
                                                        length:[NSNumber numberWithInt:plotYMaxRange]];
    }
    [self.graph reloadData];
}

+ (NSNumber*) longUnixEpoch {
    return [NSDecimalNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]; // in seconds
 }

#pragma mark - CPTPlotDataSource methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [hrValues count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
            // The xValues stores timestamps. To show them starting from 0 we have to subtract the first one.
            return [(NSDecimalNumber*)[xValues objectAtIndex:index] decimalNumberBySubtracting:(NSDecimalNumber*)[xValues firstObject]];
			break;
			
		case CPTScatterPlotFieldY:
            return [hrValues objectAtIndex:index];
			break;
	}
	return [NSDecimalNumber zero];
}

#pragma mark - CPRPlotSpaceDelegate methods

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldScaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint
{
    return NO;
}

-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)displacement {
    return CGPointMake(displacement.x, 0);
}

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    // The Y range does not change here
    if (coordinate == CPTCoordinateY) {
        return newRange;
    }
    
    // Adjust axis on scrolling
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) space.graph.axisSet;
    
    if (newRange.locationDouble >= plotXMinRange)
    {
        // Adjust axis to keep them in view at the left and bottom;
        // adjust scale-labels to match the scroll.
        axisSet.yAxis.orthogonalPosition = [NSNumber numberWithDouble:newRange.locationDouble - plotXMinRange];
        return newRange;
    }
    axisSet.yAxis.orthogonalPosition = 0;
    return [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:plotXMinRange] length:[NSNumber numberWithInt:plotXMaxRange]];
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
        [xValues removeAllObjects];
        
        [self resetPlotRange];
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
    if (!error) {
        for (CBService *hrService in peripheral.services) {
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

        }
    } else {
        NSLog(@"Error occurred while discovering service: %@",[error localizedDescription]);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:HR_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                    NSLog(@"HR Measurement characteritsic found");
                    [hrPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
                else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
                    NSLog(@"Body Sensor Location characteristic found");
                    [hrPeripheral readValueForCharacteristic:characteristic];
                }
            }
        }
        else if ([service.UUID isEqual:Battery_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:Battery_Level_Characteristic_UUID]) {
                    NSLog(@"Battery Level characteristic found");
                    [hrPeripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    } else {
        NSLog(@"Error occurred while discovering characteristic: %@",[error localizedDescription]);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                int value = [self decodeHRValue:characteristic.value];
                [self addHRValueToGraph: value];
                hrValue.text = [NSString stringWithFormat:@"%d", value];
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
            NSLog(@"Error occurred while updating characteristic value: %@",[error localizedDescription]);
        }
    });
}

-(int) decodeHRValue:(NSData *)data
{
    const uint8_t *value = [data bytes];
    int bpmValue = 0;
    if ((value[0] & 0x01) == 0) {
        bpmValue = value[1];
    }
    else {
        bpmValue = CFSwapInt16LittleToHost(*(uint16_t *)(&value[1]));
    }
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
    return hrmLocation;
}

- (void) clearUI
{
    deviceName.text = @"DEFAULT HRM";
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    battery.tag = 0;
    hrLocation.text = @"n/a";
    hrValue.text = @"-";
    
    // Clear and reset the graph
    [hrValues removeAllObjects];
    [xValues removeAllObjects];
    [self resetPlotRange];
    [self.graph reloadData];
}
@end
