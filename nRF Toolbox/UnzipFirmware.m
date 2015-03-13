//
//  UnzipFirmware.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "UnzipFirmware.h"
#import "SSZipArchive.h"
#import "AccessFileSystem.h"
#import "JsonParser.h"
#import "InitData.h"

@implementation UnzipFirmware

-(NSArray *)unzipFirmwareFiles:(NSURL *)zipFileURL
{
    self.filesURL = [[NSMutableArray alloc]init];
    NSString *zipFilePath = [zipFileURL path];
    NSString *outputPath = [self cachesPath:@"/UnzipFiles"];
    [SSZipArchive unzipFileAtPath:zipFilePath toDestination:outputPath delegate:self];
    AccessFileSystem *fileSystem = [[AccessFileSystem alloc]init];
    NSArray *files = [fileSystem getAllFilesFromDirectory:outputPath];
    NSLog(@"number of files inside zip file: %d",[files count]);
    if ([self findManifestFileInsideZip:files outputPathInPhone:outputPath]) {
        return [self.filesURL copy];
    }
    else {
        [self findFilesInsideZip:files outputPathInPhone:outputPath];
        return [self.filesURL copy];
    }    
}

-(void)findFilesInsideZip:(NSArray *)files outputPathInPhone:(NSString *)outputPath
{
    for (NSString* file in files) {
         if ([file isEqualToString:@"softdevice.hex"]) {
             NSLog(@"softdevice.hex is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"softdevice.hex"]]];
         }
         else if ([file isEqualToString:@"bootloader.hex"]) {
             NSLog(@"bootloader.hex is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"bootloader.hex"]]];
         }
         else if ([file isEqualToString:@"application.hex"]) {
             NSLog(@"application.hex is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"application.hex"]]];
         }
         else if ([file isEqualToString:@"softdevice.bin"]) {
             NSLog(@"softdevice.bin is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"softdevice.bin"]]];
         }
         else if ([file isEqualToString:@"bootloader.bin"]) {
             NSLog(@"bootloader.bin is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"bootloader.bin"]]];
         }
         else if ([file isEqualToString:@"application.bin"]) {
             NSLog(@"application.bin is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"application.bin"]]];
         }
         else if ([file isEqualToString:@"application.dat"]) {
             NSLog(@"application.dat is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"application.dat"]]];
         }
         else if ([file isEqualToString:@"bootloader.dat"]) {
             NSLog(@"bootloader.dat is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"bootloader.dat"]]];
         }
         else if ([file isEqualToString:@"softdevice.dat"]) {
             NSLog(@"softdevice.dat is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"softdevice.dat"]]];
         }
         else if ([file isEqualToString:@"system.dat"]) {
             NSLog(@"system.dat is found inside zip file");
             [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"system.dat"]]];
         }
     }
}

-(BOOL)findManifestFileInsideZip:(NSArray *)files outputPathInPhone:(NSString *)outputPath
{
    for (NSString* file in files) {
        if ([file isEqualToString:@"manifest.json"]) {
            NSLog(@"manifest.json file is found inside zip");
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"manifest.json"]]];
            JsonParser *parser = [[JsonParser alloc]init];
            InitData *packetData = [parser parseJson:data];
            [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:@"manifest.json"]]];
            [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:packetData.firmwareBinFileName]]];
            [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:packetData.firmwareDatFileName]]];
            return YES;
        }
    }
    return NO;
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
