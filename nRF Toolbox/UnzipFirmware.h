//
//  UnzipFirmware.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSZipArchive.h"

@interface UnzipFirmware : NSObject <SSZipArchiveDelegate>

-(NSArray *)unzipFirmwareFiles:(NSURL *)zipFileURL;

@end
