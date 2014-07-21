//
//  AccessFileSystem.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 09/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccessFileSystem : NSObject

-(NSArray *)getFilesFromDocumentsDirectory;
-(NSArray *)getFilesFromAppDirectory:(NSString *)directoryName;
-(NSArray *)getFilesFromInboxDirectory;
-(NSString *)getAppDirectoryPath:(NSString *)directoryName;
-(NSString *)getDocumentsDirectoryPath;
-(NSString *)getInboxDirectoryPath;
@end
