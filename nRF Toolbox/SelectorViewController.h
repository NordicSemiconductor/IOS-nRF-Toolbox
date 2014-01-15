//
//  SelectorViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 14/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectorDelegate.h"

@interface SelectorViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) id <SelectorDelegate> delegate;
@property (weak, nonatomic) IBOutlet UICollectionView *gridView;

/*!
 * Cancel button has been clicked
 */
- (IBAction)didCancelClicked:(id)sender;

@end
