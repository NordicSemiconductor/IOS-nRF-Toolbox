//
//  AppFilesTableViewController.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 21/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FileSelectionDelegate <NSObject>

-(void)onFileSelected:(NSURL *)fileURL;

@end

@interface AppFilesTableViewController : UITableViewController <UITabBarControllerDelegate>

- (IBAction)CancelBarButtonPressed:(UIBarButtonItem *)sender;

//define delegate property
@property (retain)id<FileSelectionDelegate> fileDelegate;

@end
