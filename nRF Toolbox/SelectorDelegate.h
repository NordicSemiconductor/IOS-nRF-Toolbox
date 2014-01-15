//
//  SelectorDelegate.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 14/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SelectorDelegate <NSObject>

-(void)fileSelected:(NSURL*)url;
@end
