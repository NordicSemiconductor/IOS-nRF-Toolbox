//
//  AccessFileSystem.h
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 09/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utility.h"

@interface AccessFileSystem : NSObject

//Get App Main Bundle path
-(NSString *)getAppDirectoryPath:(NSString *)directoryName;
//Get Documents directory path inside Home directory
-(NSString *)getDocumentsDirectoryPath;

//Get All files provided by app itself from App Main Bundle
-(NSArray *)getFilesFromAppDirectory:(NSString *)directoryName;
//Get All directories, hex and zip files from Documents directory inside Home directory
-(NSArray *)getDirectoriesAndRequiredFilesFromDocumentsDirectory;
//Get Hex and Zip files from Documents Directory inside Home Directory
-(NSArray *)getRequiredFilesFromDocumentsDirectory;
//Get All directories and files inside given directory path
-(NSArray *)getAllFilesFromDirectory:(NSString *)directoryPath;
//Get All directories and files under Documents directory inside Home directory
-(NSArray *)getAllFilesFromDocumentsDirectory;
//Get hex and zip files inside given directory path
-(NSArray *)getRequiredFilesFromDirectory:(NSString *)directoryPath;
//Get files with given file extension and directory path
-(NSArray *)getFilesFromDirectory:(NSString *)directoryPath fileExtension:(enumFileExtension)fileExtension;
//Get only directories inside Documents directory
-(NSArray *)getSubDirectoriesInDocumentsDirectory;

//check if given path is directory or not
-(BOOL)isDirectory:(NSString *)path;
//check if given file has given extension
-(BOOL)checkFileExtension:(NSString *)fileName fileExtension:(enumFileExtension)fileExtension;

-(void)deleteFile:(NSString *)path;
@end
