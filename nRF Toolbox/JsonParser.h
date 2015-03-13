//
//  JsonParser.h
//  TestJson
//
//  Created by Kamran Saleem Soomro on 12/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InitData.h"

@interface JsonParser : NSObject



@property (nonatomic, retain)InitData *packetData;

-(InitData *)parseJson:(NSData *)data;



@end
