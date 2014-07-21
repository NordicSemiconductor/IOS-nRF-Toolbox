//
//  AccessFileSystem.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 09/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "AccessFileSystem.h"

@implementation AccessFileSystem

-(NSArray *)getFilesFromDocumentsDirectory
{
    NSLog(@"getFilesFromDocumentsDirectory");
    NSString *documentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];    
    return [self getFilesFromDirectory:documentDirectoryPath];
}

-(NSArray *)getFilesFromAppDirectory:(NSString *)directoryName
{
    NSString *firmwaresDirectoryPath = [self getAppDirectoryPath:directoryName];
    return [self getFilesFromDirectory:firmwaresDirectoryPath];
}

-(NSArray *)getFilesFromInboxDirectory
{
    NSLog(@"getFilesFromInboxDirectory");
    NSString *inboxDirectoryPath = [self getInboxDirectoryPath];
    return [self getFilesFromDirectory:inboxDirectoryPath];
}

-(NSArray *)getFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *filesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *filePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else {
        NSLog(@"number of files in directory %d",filePaths.count);
        for (int index=0; index<filePaths.count; index++) {
            NSLog(@"Found file in directory: %@",[filePaths objectAtIndex:index]);
            [filesNames addObject:[filePaths objectAtIndex:index]];
        }
        return [filesNames copy];
    }
}

-(NSString *)getAppDirectoryPath:(NSString *)directoryName
{
    NSLog(@"getFilesFromDirectory");
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"app resource path: %@",appPath);
    NSString *firmwaresDirectoryPath = [appPath stringByAppendingPathComponent:directoryName];
    NSLog(@"firmware folder path: %@",firmwaresDirectoryPath);
    return firmwaresDirectoryPath;
}

-(NSString *)getDocumentsDirectoryPath
{
    NSString *documentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return documentDirectoryPath;
}

-(NSString *)getInboxDirectoryPath
{
    NSString *inboxDirectoryPath = [[self getDocumentsDirectoryPath] stringByAppendingPathComponent:@"Inbox"];
    return inboxDirectoryPath;
}


@end
