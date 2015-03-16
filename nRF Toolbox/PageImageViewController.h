//
//  PageImageViewController.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 23/01/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *pageImage;

- (IBAction)skipButtonPressed:(UIButton *)sender;

@property NSUInteger pageIndex;
@property NSString *pageImageFileName;


@end
