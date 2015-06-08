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

#import "UnzipFirmware.h"
#import "SSZipArchive.h"
#import "AccessFileSystem.h"

@implementation UnzipFirmware

-(NSArray *)unzipFirmwareFiles:(NSURL *)zipFileURL
{
    self.filesURL = [[NSMutableArray alloc]init];
    NSString *zipFilePath = [zipFileURL path];
    NSString *outputPath = [self cachesPath:@"/UnzipFiles"];
    [SSZipArchive unzipFileAtPath:zipFilePath toDestination:outputPath delegate:self];
    AccessFileSystem *fileSystem = [[AccessFileSystem alloc]init];
    NSArray *files = [fileSystem getAllFilesFromDirectory:outputPath];
    NSLog(@"number of files inside zip file: %lu",(unsigned long)[files count]);
    if ([self findManifestFileInsideZip:files outputPathInPhone:outputPath]) {
        return [self getAllFilesURLInsideZipFile:files outputPathInPhone:outputPath];
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
            return YES;
        }
    }
    return NO;
}
-(NSArray *)getAllFilesURLInsideZipFile:files outputPathInPhone:outputPath
{
    for (NSString* file in files) {
        NSLog(@"with Manifest, Inside Zip found file: %@",file);
        [self.filesURL addObject:[NSURL fileURLWithPath:[outputPath stringByAppendingPathComponent:file]]];
    }
    return [self.filesURL copy];
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
    NSLog(@"zipArchiveDidUnzipFileAtIndex, fileIndex: %ld, totalFiles: %ld, archivePath: %@",(long)fileIndex,(long)totalFiles,archivePath);
}

-(void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total
{
    NSLog(@"zipArchiveProgressEvent, loaded: %ld, total: %ld",(long)loaded,(long)total);
}

-(void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo
{
    NSLog(@"zipArchiveWillUnzipArchiveAtPath, path: %@",path);
}

-(void)zipArchiveWillUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString *)archivePath fileInfo:(unz_file_info)fileInfo
{
    NSLog(@"zipArchiveWillUnzipFileAtIndex fileIndex: %ld totalFiles: %ld archivePath: %@",(long)fileIndex,(long)totalFiles,archivePath);
}

@end
