//
//  LogViewController.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 03/06/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothManager.h"

@interface LogViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *logText;

@property (weak, nonatomic) IBOutlet UITableView *displayLogTextTable;
@property (weak, nonatomic) IBOutlet UITextField *commandTextField;

@property (strong, nonatomic) BluetoothManager *uartBluetoothManager;
@property (strong, nonatomic) NSString *uartPeripheralName;
@property BOOL isRXCharacteristicFound;
@property BOOL isUartPeripheralConnected;


@end
