//
//  ScannerViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include "ScannerDelegate.h"

@interface ScannerViewController : UIViewController <CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) IBOutlet UITableView *devicesTable;
@property (weak, nonatomic) id <ScannerDelegate> delegate;

/*!
 * Cancel button has been clicked
 */
- (IBAction)didCancelClicked:(id)sender;

@end
