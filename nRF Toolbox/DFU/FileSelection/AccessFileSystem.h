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
-(NSArray *)getFilesFromDirectory:(NSString *)directoryPath fileExtension:(NSString *)fileExtension;
//Get only directories inside Documents directory
-(NSArray *)getSubDirectoriesInDocumentsDirectory;

//check if given path is directory or not
-(BOOL)isDirectory:(NSString *)path;
//check if given file has given extension
-(BOOL)checkFileExtension:(NSString *)fileName fileExtension:(NSString *)fileExtension;

-(void)deleteFile:(NSString *)path;
@end
