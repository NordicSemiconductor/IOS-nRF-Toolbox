//
//  FolderFilesTableViewController.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 23/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppFilesTableViewController.h"

@interface FolderFilesTableViewController : UITableViewController

@property (nonatomic, strong)NSMutableArray *files;
@property (nonatomic, strong)NSString *directoryPath;

//define delegate property
@property (retain)id<FileSelectionDelegate> fileDelegate;

@end
