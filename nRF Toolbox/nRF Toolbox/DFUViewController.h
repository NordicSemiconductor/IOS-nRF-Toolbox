//
//  DFUViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 10/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"
#import "FileTypeTableViewController.h"
#import "AppFilesTableViewController.h"
#import "DFUOperations.h"

@interface DFUViewController : UIViewController <ScannerDelegate, FileSelectionDelegate, DFUOperationsDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic)NSString *selectedFileType;

@end
