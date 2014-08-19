//
//  UnzipFirmware.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "UnzipFirmware.h"
#import "SSZipArchive.h"
#import "AccessFileSystem.h"

@implementation UnzipFirmware

-(NSArray *)unzipFirmwareFiles:(NSURL *)zipFileURL
{
    NSMutableArray *filesURL = [[NSMutableArray alloc]init];
    NSString *zipFilePath = [zipFileURL path];
    NSLog(@"unzipFirmwareFiles");
    NSLog(@"zipFileURL %@",zipFileURL);
    NSLog(@"zipFilePath %@",zipFilePath);
    NSString *outputPath = [self cachesPath:@"/UnzipFiles"];
    [SSZipArchive unzipFileAtPath:zipFilePath toDestination:outputPath delegate:self];
    NSLog(@"unzip folder path: %@",outputPath);
    AccessFileSystem *fileSystem = [[AccessFileSystem alloc]init];
    NSLog(@"number of files inside zip file: %d",[[fileSystem getAllFilesFromDirectory:outputPath] count]);
    NSString *softdevicePath, *bootloaderPath, *applicationPath;
    NSArray *files = [fileSystem getAllFilesFromDirectory:outputPath];
    NSLog(@"number of files inside zip file: %d",[files count]);
    for (NSString* file in files) {
        NSLog(@"file inside zip file: %@",file);
        if ([file isEqualToString:@"softdevice.hex"]) {
            NSLog(@"Found softdevice.hex in zip file");
            softdevicePath = [outputPath stringByAppendingPathComponent:@"softdevice.hex"];
            [filesURL addObject:[NSURL fileURLWithPath:softdevicePath]];
        }
        else if ([file isEqualToString:@"bootloader.hex"]) {
            NSLog(@"Found bootloader.hex in zip file");
            bootloaderPath = [outputPath stringByAppendingPathComponent:@"bootloader.hex"];
            [filesURL addObject:[NSURL fileURLWithPath:bootloaderPath]];
        }
        else if ([file isEqualToString:@"application.hex"]) {
            NSLog(@"Found application.hex in zip file");
            applicationPath = [outputPath stringByAppendingPathComponent:@"application.hex"];
            [filesURL addObject:[NSURL fileURLWithPath:applicationPath]];
        }
    }
    return [filesURL copy];
}

-(NSString *)cachesPath:(NSString *)directory {
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                      stringByAppendingPathComponent:@"com.nordicsemi.nRFToolbox"];
	if (directory) {
		path = [path stringByAppendingPathComponent:directory];
	}
    
	NSFileManager *fileManager = [NSFileManager defaultManager];    
	if (![fileManager fileExistsAtPath:path]) {
        NSLog(@"creating unzip directory under Cache");
		[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	}
    else {
        NSLog(@"unzip directory already exist. removing it and then creating one");
        [fileManager removeItemAtPath:path error:nil];
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
	return path;
}

-(void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath
{
    NSLog(@"zipArchiveDidUnzipArchiveAtPath, path: %@, unzippedPath: %@",path,unzippedPath);
}

-(void)zipArchiveDidUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString *)archivePath fileInfo:(unz_file_info)fileInfo
{
    NSLog(@"zipArchiveDidUnzipFileAtIndex, fileIndex: %d, totalFiles: %d, archivePath: %@",fileIndex,totalFiles,archivePath);
}

-(void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total
{
    NSLog(@"zipArchiveProgressEvent, loaded: %d, total: %d",loaded,total);
}

-(void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo
{
    NSLog(@"zipArchiveWillUnzipArchiveAtPath, path: %@",path);
}

-(void)zipArchiveWillUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString *)archivePath fileInfo:(unz_file_info)fileInfo
{
    NSLog(@"zipArchiveWillUnzipFileAtIndex fileIndex: %d totalFiles: %d archivePath: %@",fileIndex,totalFiles,archivePath);
}



@end
