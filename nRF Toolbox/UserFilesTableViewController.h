//
//  UserFilesTableViewController.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 21/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppFilesTableViewController.h"

@interface UserFilesTableViewController : UITableViewController<UIPageViewControllerDataSource>

- (IBAction)cancelBarButtonPressed:(UIBarButtonItem *)sender;

//define delegate property
@property (retain)id<FileSelectionDelegate> fileDelegate;

@property (weak, nonatomic) IBOutlet UITextView *emptyMessageText;

@property (strong, nonatomic)NSArray *pageContentImages;
@property (strong, nonatomic)UIPageViewController *pageViewController;

@end
