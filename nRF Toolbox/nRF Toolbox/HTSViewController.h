//
//  HTSViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 09/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"

@interface HTSViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UIButton *battery;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (weak, nonatomic) IBOutlet UISegmentedControl *degreeControl;
@property (weak, nonatomic) IBOutlet UILabel *temperature;
@property (weak, nonatomic) IBOutlet UILabel *degrees;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *type;

- (IBAction)connectOrDisconnectClicked;
- (IBAction)degreeHasChanged:(id)sender forEvent:(UIEvent *)event;

@end
