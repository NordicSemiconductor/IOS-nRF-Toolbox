//
//  AppUtilities.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 09/04/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppUtilities : NSObject

+ (void) showAlert:(NSString *)title alertMessage:(NSString *)message;
+ (void)showBackgroundNotification:(NSString *)message;
+ (BOOL)isApplicationStateInactiveORBackground;
+ (NSString *) getUARTHelpText;
+ (NSString *) getRSACHelpText;
+ (NSString *) getProximityHelpText;
+ (NSString *) getHTSHelpText;
+ (NSString *) getHRSHelpText;
+ (NSString *) getCSCHelpText;
+ (NSString *) getBPMHelpText;
+ (NSString *) getBGMHelpText;

@end
