//
//  HRSViewController.h
//  nRF Toolbox
//
//  Created by Kamran Soomro on 09/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"
#import "CorePlot-CocoaTouch.h"

@interface HRSViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate, CPTPlotDataSource>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UIButton *battery;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *hrValue;
@property (weak, nonatomic) IBOutlet UILabel *hrLocation;

@property (weak, nonatomic) IBOutlet UIView *graphView;

- (IBAction)connectOrDisconnectClicked;

@end
