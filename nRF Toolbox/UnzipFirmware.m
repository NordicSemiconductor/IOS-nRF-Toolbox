//
//  UnzipFirmware.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 07/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "UnzipFirmware.h"
#import "SSZipArchive.h"

@implementation UnzipFirmware

-(NSArray *)unzipFirmwareFiles:(NSURL *)zipFileURL
{
    NSMutableArray *filesURL = [[NSMutableArray alloc]init];
    NSLog(@"unzipFirmwareFiles");
    //NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"firmware" ofType:@"zip"];
    NSString *zipPath = [zipFileURL absoluteString];
    
    NSString *outputPath = [self _cachesPath:@"unzipFiles"];
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:outputPath];
    NSLog(@"zipfile path: %@",zipPath);
    NSLog(@"unzip folder path: %@",outputPath);
    //path to softdevice, bootloader and application
    NSString *softdevicePath = [outputPath stringByAppendingPathComponent:@"softdevice.hex"];
    NSString *bootloaderPath = [outputPath stringByAppendingPathComponent:@"bootloader.hex"];
    NSString *blinkyappPath = [outputPath stringByAppendingPathComponent:@"application.hex"];
    
    [filesURL insertObject:[NSURL fileURLWithPath:softdevicePath] atIndex:0];
    [filesURL insertObject:[NSURL fileURLWithPath:bootloaderPath] atIndex:1];
    [filesURL insertObject:[NSURL fileURLWithPath:blinkyappPath] atIndex:2];
    
    return [filesURL copy];
}

-(NSString *)_cachesPath:(NSString *)directory {
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                      stringByAppendingPathComponent:@"com.nordicsemi.nRFToolbox"];
	if (directory) {
		path = [path stringByAppendingPathComponent:directory];
	}
    
	NSFileManager *fileManager = [NSFileManager defaultManager];    
	if (![fileManager fileExistsAtPath:path]) {
		[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	}
    
	return path;
}

@end
