//
//  RSACViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 13/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"

@interface RSACViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UIButton *battery;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (weak, nonatomic) IBOutlet UILabel *speed;
@property (weak, nonatomic) IBOutlet UILabel *cadence;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *distanceUnit;
@property (weak, nonatomic) IBOutlet UILabel *totalDistance;
@property (weak, nonatomic) IBOutlet UILabel *totalDistanceUnit;
@property (weak, nonatomic) IBOutlet UILabel *strides;
@property (weak, nonatomic) IBOutlet UILabel *activity;

- (IBAction)connectOrDisconnectClicked;

@end
