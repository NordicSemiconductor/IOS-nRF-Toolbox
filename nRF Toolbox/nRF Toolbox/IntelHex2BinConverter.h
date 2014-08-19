//
//  IntelHex2BinConverter.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 15/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntelHex2BinConverter : NSObject

/*!
 * Converts the Intel HEX data to a bin format by subtracting only the data part from it.
 Current implemetation does not support Extended Segment Addresses or Extended Linear Addresses.
 */
+ (NSData*)convert:(NSData*)hex;
@end
