//
//  BGMDetailsViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlucoseReading.h"

@interface BGMDetailsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@property (strong, nonatomic) GlucoseReading* reading;

@end
