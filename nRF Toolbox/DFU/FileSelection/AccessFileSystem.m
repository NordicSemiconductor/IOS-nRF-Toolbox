/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
    if (error)
    {
        NSLog(@"error in opening directory path: %@",[self getDocumentsDirectoryPath]);
        return nil;
    }
    else
    {
        NSLog(@"number of files in directory %lu",(unsigned long)fileNames.count);
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
    [requiredFilesNames addObjectsFromArray:[self getBinFilesFromDirectory:directoryPath]];
    return requiredFilesNames;
}

-(NSArray *)getBinFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *binFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error)
    {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else
    {
        for (NSString *fileName in fileNames)
        {
            if ([self checkFileExtension:fileName fileExtension:@"bin"])
            {
                [binFilesNames addObject:fileName];
            }
        }
        return [binFilesNames copy];
    }
}


-(NSArray *)getHexFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray *hexFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error)
    {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else
    {
        for (NSString *fileName in fileNames)
        {
            if ([self checkFileExtension:fileName fileExtension:@"hex"])
            {
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
    if (error)
    {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else
    {
        for (NSString *fileName in fileNames)
        {
            if ([self checkFileExtension:fileName fileExtension:@"zip"])
            {
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
    if (error)
    {
        NSLog(@"error in opening directory path: %@",directoryPath);
        return nil;
    }
    else
    {
        for (NSString *fileName in fileNames)
        {
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
    for (NSString *file in documentsFiles)
    {
        filePath = [documentsDirectoryPath stringByAppendingPathComponent:file];
        if ([self isDirectory:filePath])
        {
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
    if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory])
    {
        return isDirectory;
    }
    else
    {
        return NO;
    }
}

-(BOOL)checkFileExtension:(NSString *)fileName fileExtension:(NSString*)fileExtension
{
    NSString *extension = [[fileName pathExtension] lowercaseString];
    return [extension isEqualToString:fileExtension];
}

-(NSArray *)getFilesFromDirectory:(NSString *)directoryPath fileExtension:(NSString*)fileExtension
{
    NSMutableArray *filesWithExt = [[NSMutableArray alloc]init];
    NSArray *files = [self getAllFilesFromDirectory:directoryPath];
    for (NSString *file in files)
    {
        NSString *extension = [[file pathExtension] lowercaseString];
        if ([extension isEqualToString:fileExtension]) {
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
    if (error)
    {
        NSLog(@"%@ is not removed", path);
    }
    else
    {
        NSLog(@"%@ is removed successfully", path);
    }
}

@end
