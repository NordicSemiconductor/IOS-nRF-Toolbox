//
//  AccessFileSystem.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 09/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "AccessFileSystem.h"
#import "Utility.h"

@implementation AccessFileSystem

-(NSArray *)getRequiredFilesFromDocumentsDirectory
{
    NSLog(@"getFilesFromDocumentsDirectory");
    return [self getRequiredFilesFromDirectory:[self getDocumentsDirectoryPath]];
}

-(NSArray *)getAllFilesFromDocumentsDirectory
{
    NSLog(@"getFilesFromDocumentsDirectory");
    return [self getAllFilesFromDirectory:[self getDocumentsDirectoryPath]];
}

-(NSArray *)getDirectoriesAndRequiredFilesFromDocumentsDirectory
{
    NSMutableArray *allFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getDocumentsDirectoryPath] error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",[self getDocumentsDirectoryPath]);
        return nil;
    }
    else {
        NSLog(@"number of files in directory %d",fileNames.count);
        [allFilesNames addObjectsFromArray:[self getSubDirectoriesInDocumentsDirectory]];
        [allFilesNames addObjectsFromArray:[self getRequiredFilesFromDocumentsDirectory]];
        return [allFilesNames copy];
    }
}

-(NSArray *)getFilesFromAppDirectory:(NSString *)directoryName
{
    NSString *firmwaresDirectoryPath = [self getAppDirectoryPath:directoryName];
    return [self getAllFilesFromDirectory:firmwaresDirectoryPath];
}

-(NSArray *)getRequiredFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *requiredFilesNames = [[NSMutableArray alloc]init];
    [requiredFilesNames addObjectsFromArray:[self getZipFilesFromDirectory:directoryPath]];
    [requiredFilesNames addObjectsFromArray:[self getHexFilesFromDirectory:directoryPath]];
    return requiredFilesNames;
}

-(NSArray *)getHexFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *hexFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else {
        NSLog(@"number of hex files in directory %d",fileNames.count);
        for (NSString *fileName in fileNames) {
            if ([self checkFileExtension:fileName fileExtension:HEX]) {
                [hexFilesNames addObject:fileName];
            }
        }
        return [hexFilesNames copy];
    }
}

-(NSArray *)getZipFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *zipFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else {
        NSLog(@"number of zip files in directory %d",fileNames.count);
        for (NSString *fileName in fileNames) {
            if ([self checkFileExtension:fileName fileExtension:ZIP]) {
                [zipFilesNames addObject:fileName];
            }
        }
        return [zipFilesNames copy];
    }
}

-(NSArray *)getAllFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *AllFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else {
        NSLog(@"number of files in directory %d",fileNames.count);
        for (NSString *fileName in fileNames) {
            NSLog(@"Found file in directory: %@",fileName);
            [AllFilesNames addObject:fileName];
        }
        return [AllFilesNames copy];
    }
}

-(NSArray *)getSubDirectoriesInDocumentsDirectory
{
    NSMutableArray *directories = [[NSMutableArray alloc]init];
    NSArray *documentsFiles = [self getAllFilesFromDocumentsDirectory];
    NSString *documentsDirectoryPath = [self getDocumentsDirectoryPath];
    NSString *filePath;
    for (NSString *file in documentsFiles) {
        filePath = [documentsDirectoryPath stringByAppendingPathComponent:file];
        if ([self isDirectory:filePath]) {
            NSLog(@"Found Directory: %@",file);
            [directories addObject:file];

        }
    }    
    return [directories copy];
}

-(BOOL)isDirectory:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        return isDirectory;
    }
    else {
        return NO;
    }
}

-(BOOL)checkFileExtension:(NSString *)fileName fileExtension:(enumFileExtension)fileExtension
{
    if ([[fileName pathExtension] isEqualToString:[Utility stringFileExtension:fileExtension]]) {
        return YES;
    }
    else {
        return NO;
    }
}

-(NSArray *)getFilesFromDirectory:(NSString *)directoryPath fileExtension:(enumFileExtension)fileExtension
{
    NSMutableArray *filesWithExt = [[NSMutableArray alloc]init];
    NSArray *files = [self getAllFilesFromDirectory:directoryPath];
    for (NSString *file in files) {
        if ([[file pathExtension] isEqualToString:[Utility stringFileExtension:fileExtension]]) {
            [filesWithExt addObject:file];
        }
    }
    return [filesWithExt copy];
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

-(void)deleteFile:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%@ is not removed",path);
    }
    else {
        NSLog(@"%@ is removed successfully",path);
    }
}

@end
