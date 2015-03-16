//
//  InitData.h
//  TestJson
//
//  Created by Kamran Saleem Soomro on 11/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utility.h"


@interface InitData : NSObject
@property (nonatomic, retain)NSString *firmwareBinFileName;
@property (nonatomic, retain)NSString *firmwareDatFileName;
@property (nonatomic)DfuFirmwareTypes firmwareType;
@property (nonatomic)uint32_t bootloaderSize;
@property (nonatomic)uint32_t softdeviceSize;
@property (nonatomic)long applicationVersion;
@property (nonatomic)int deviceRevision;
@property (nonatomic)int deviceType;
@property (nonatomic)int firmwareCRC;
@property (nonatomic)NSArray *softdeviceRequired;


@end
