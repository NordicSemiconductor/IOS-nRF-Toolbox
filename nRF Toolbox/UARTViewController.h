//
//  UARTViewController.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 17/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScannerDelegate.h"

@interface UARTViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) CBPeripheral *uartPeripheral;
@property (strong, nonatomic)CBCharacteristic *uartRXCharacteristic;
@property (strong, nonatomic) NSMutableArray *uartDisplayText;


- (IBAction)connectOrDisconnectClicked:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextField *uartRXText;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UITableView *displayText;

@end
