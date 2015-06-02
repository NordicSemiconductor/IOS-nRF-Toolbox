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

#import "DFUHelper.h"
#import "UnzipFirmware.h"
#import "JsonParser.h"
#import "Utility.h"

@implementation DFUHelper

-(DFUHelper *)initWithData:(DFUOperations *)dfuOperations
{
    if (self = [super init]) {
        self.dfuOperations = dfuOperations;
    }
    return self;
}

-(void)checkAndPerformDFU
{
    if (self.isSelectedFileZipped) {
        switch (self.enumFirmwareType) {
            case SOFTDEVICE_AND_BOOTLOADER:
                if (self.isDfuVersionExist) {
                    if (self.isManifestExist) {
                        [self.dfuOperations performDFUOnFileWithMetaDataAndFileSizes:self.softdevice_bootloaderURL firmwareMetaDataURL:self.systemMetaDataURL softdeviceFileSize:self.softdeviceSize bootloaderFileSize:self.bootloaderSize firmwareType:SOFTDEVICE_AND_BOOTLOADER];
                    }
                    else {
                        [self.dfuOperations performDFUOnFilesWithMetaData:self.softdeviceURL bootloaderURL:self.bootloaderURL firmwaresMetaDataURL:self.systemMetaDataURL firmwareType:SOFTDEVICE_AND_BOOTLOADER];
                    }
                    
                }
                else {
                    [self.dfuOperations performDFUOnFiles:self.softdeviceURL bootloaderURL:self.bootloaderURL firmwareType:SOFTDEVICE_AND_BOOTLOADER];
                }
                
                break;
            case SOFTDEVICE:
                if (self.isDfuVersionExist) {
                    [self.dfuOperations performDFUOnFileWithMetaData:self.softdeviceURL firmwareMetaDataURL:self.softdeviceMetaDataURL firmwareType:SOFTDEVICE];
                }
                else {
                    [self.dfuOperations performDFUOnFile:self.softdeviceURL firmwareType:SOFTDEVICE];
                }
                break;
            case BOOTLOADER:
                if (self.isDfuVersionExist) {
                    [self.dfuOperations performDFUOnFileWithMetaData:self.bootloaderURL firmwareMetaDataURL:self.bootloaderMetaDataURL firmwareType:BOOTLOADER];
                }
                else {
                    [self.dfuOperations performDFUOnFile:self.bootloaderURL firmwareType:BOOTLOADER];
                }
                break;
            case APPLICATION:
                if (self.isDfuVersionExist) {
                    [self.dfuOperations performDFUOnFileWithMetaData:self.applicationURL firmwareMetaDataURL:self.applicationMetaDataURL firmwareType:APPLICATION];
                }
                else {
                    [self.dfuOperations performDFUOnFile:self.applicationURL firmwareType:APPLICATION];
                }
                break;
                
            default:
                NSLog(@"Not valid File type");
                break;
        }
    }
    else {
        [self.dfuOperations performDFUOnFile:self.selectedFileURL firmwareType:self.enumFirmwareType];
    }
}

//Unzip and check if both bin and hex formats are present for same file then pick only bin format and drop hex format
-(void)unzipFiles:(NSURL *)zipFileURL
{
    self.softdeviceURL = self.bootloaderURL = self.applicationURL = nil;
    self.softdeviceMetaDataURL = self.bootloaderMetaDataURL = self.applicationMetaDataURL = self.systemMetaDataURL = nil;
    UnzipFirmware *unzipFiles = [[UnzipFirmware alloc]init];
    NSArray *firmwareFilesURL = [unzipFiles unzipFirmwareFiles:zipFileURL];
    // if manifest file exist inside then parse it and retrieve the files from the given path
    if ([self checkIfManifestFileExist:firmwareFilesURL]) {
        self.isManifestExist = YES;
        [self parseManifestFile];
        [self getBinAndDatFilesAsMentionedInManfest:firmwareFilesURL jsonParsedData:self.manifestData];
        return;
    }
    [self getHexAndDatFile:firmwareFilesURL];
    [self getBinFiles:firmwareFilesURL];
}

-(BOOL)checkIfManifestFileExist:(NSArray *)firmwareFilesURL
{
    self.manifestFileURL = nil;
    for (NSURL *firmwareManifestURL in firmwareFilesURL) {
        if ([[[firmwareManifestURL path] lastPathComponent] isEqualToString:@"manifest.json"]) {
            self.manifestFileURL = firmwareManifestURL;
            return YES;
        }
    }
    return NO;
}

-(void)parseManifestFile
{
    NSData *data = [NSData dataWithContentsOfURL:self.manifestFileURL];
    self.manifestData = [[[JsonParser alloc]init] parseJson:data];
}

-(void)getBinAndDatFilesAsMentionedInManfest:(NSArray *)firmwareFilesURL jsonParsedData:(NSArray *)jsonData
{
    for (InitData *data in jsonData) {
        for (NSURL *firmwareURL in firmwareFilesURL) {
            if ([[[firmwareURL path] lastPathComponent] isEqualToString:data.firmwareBinFileName]) {
                if (data.firmwareType == SOFTDEVICE) {
                    self.softdeviceURL = firmwareURL;
                }
                else if (data.firmwareType == BOOTLOADER) {
                    self.bootloaderURL = firmwareURL;
                }
                else if (data.firmwareType == APPLICATION)
                {
                    self.applicationURL = firmwareURL;
                }
                else if (data.firmwareType == SOFTDEVICE_AND_BOOTLOADER)
                {
                    self.softdevice_bootloaderURL = firmwareURL;
                    self.softdeviceSize = data.softdeviceSize;
                    self.bootloaderSize = data.bootloaderSize;
                }
            }
            else if ([[[firmwareURL path] lastPathComponent] isEqualToString:data.firmwareDatFileName]) {
                if (data.firmwareType == SOFTDEVICE) {
                    self.softdeviceMetaDataURL = firmwareURL;
                }
                else if (data.firmwareType == BOOTLOADER) {
                    self.bootloaderMetaDataURL = firmwareURL;
                }
                else if (data.firmwareType == APPLICATION)
                {
                    self.applicationMetaDataURL = firmwareURL;
                }
                else if (data.firmwareType == SOFTDEVICE_AND_BOOTLOADER)
                {
                    self.systemMetaDataURL = firmwareURL;
                }
            }
        }

    }
}

-(void)getHexAndDatFile:(NSArray *)firmwareFilesURL
{
    for (NSURL *firmwareURL in firmwareFilesURL) {
        if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"softdevice.hex"]) {
            self.softdeviceURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"bootloader.hex"]) {
            self.bootloaderURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"application.hex"]) {
            self.applicationURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"application.dat"]) {
            self.applicationMetaDataURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"bootloader.dat"]) {
            self.bootloaderMetaDataURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"softdevice.dat"]) {
            self.softdeviceMetaDataURL = firmwareURL;
        }
        else if ([[[firmwareURL path] lastPathComponent] isEqualToString:@"system.dat"]) {
            self.systemMetaDataURL = firmwareURL;
        }
    }
}

-(void)getBinFiles:(NSArray *)firmwareFilesURL
{
    for (NSURL *firmwareBinURL in firmwareFilesURL) {
        if ([[[firmwareBinURL path] lastPathComponent] isEqualToString:@"softdevice.bin"]) {
            self.softdeviceURL = firmwareBinURL;
        }
        else if ([[[firmwareBinURL path] lastPathComponent] isEqualToString:@"bootloader.bin"]) {
            self.bootloaderURL = firmwareBinURL;
        }
        else if ([[[firmwareBinURL path] lastPathComponent] isEqualToString:@"application.bin"]) {
            self.applicationURL = firmwareBinURL;
        }
    }
}

-(void) setFirmwareType:(NSString *)firmwareType
{
    if ([firmwareType isEqualToString:FIRMWARE_TYPE_SOFTDEVICE]) {
        self.enumFirmwareType = SOFTDEVICE;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_BOOTLOADER]) {
        self.enumFirmwareType = BOOTLOADER;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER]) {
        self.enumFirmwareType = SOFTDEVICE_AND_BOOTLOADER;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_APPLICATION]) {
        self.enumFirmwareType = APPLICATION;
    }
}

-(BOOL)isInitPacketFileExist
{
    //Zip file is required with firmware and .dat files
    if (self.isSelectedFileZipped) {
        switch (self.enumFirmwareType) {
            case SOFTDEVICE_AND_BOOTLOADER:
                if (self.systemMetaDataURL) {
                    NSLog(@"Found system.dat in selected zip file");
                    return YES;
                }
                break;
            case SOFTDEVICE:
                if (self.softdeviceMetaDataURL) {
                    NSLog(@"Found softdevice.dat file in selected zip file");
                    return YES;
                }
                break;
            case BOOTLOADER:
                if (self.bootloaderMetaDataURL) {
                    NSLog(@"Found Bootloader.dat file in selected zip file");
                    return YES;
                }
                break;
            case APPLICATION:
                if (self.applicationMetaDataURL) {
                    NSLog(@"Found Application.dat file in selected zip file");
                    return YES;
                }
                break;
                
            default:
                NSLog(@"Not valid File type");
                return NO;
                break;
        }
        //Corresponding file .dat to selected firmware is not present in zip file
        return NO;
    }
    else {//Zip file is not selected
        return NO;
    }
}

-(BOOL)isValidFileSelected
{
    NSLog(@"isValidFileSelected");
    if (self.isSelectedFileZipped) {
        switch (self.enumFirmwareType) {
            case SOFTDEVICE_AND_BOOTLOADER:
                if (self.isManifestExist) {
                    if (self.softdevice_bootloaderURL) {
                        NSLog(@"Found Softdevice_Bootloader file in selected zip file");
                        return YES;
                    }
                }
                else {
                    if (self.softdeviceURL && self.bootloaderURL) {
                        NSLog(@"Found Softdevice and Bootloader files in selected zip file");
                        return YES;
                    }
                }
                
                break;
            case SOFTDEVICE:
                if (self.softdeviceURL) {
                    NSLog(@"Found Softdevice file in selected zip file");
                    return YES;
                }
                break;
            case BOOTLOADER:
                if (self.bootloaderURL) {
                    NSLog(@"Found Bootloader file in selected zip file");
                    return YES;
                }
                break;
            case APPLICATION:
                if (self.applicationURL) {
                    NSLog(@"Found Application file in selected zip file");
                    return YES;
                }
                break;
                
            default:
                NSLog(@"Not valid File type");
                return NO;
                break;
        }
        //Corresponding file to selected file type is not present in zip file
        return NO;
    }
    else if(self.enumFirmwareType == SOFTDEVICE_AND_BOOTLOADER){
        NSLog(@"Please select zip file with softdevice and bootloader inside");
        return NO;
    }
    else {
        //Selcted file is not zip and file type is not Softdevice + Bootloader
        //then it is upto user to assign correct file to corresponding file type
        return YES;
    }
}

-(NSString *)getUploadStatusMessage
{
    switch (self.enumFirmwareType) {
        case SOFTDEVICE:
            return @"uploading softdevice ...";
            break;
        case BOOTLOADER:
            return @"uploading bootloader ...";
            break;
        case APPLICATION:
            return @"uploading application ...";
            break;
        case SOFTDEVICE_AND_BOOTLOADER:
            if (self.isManifestExist) {
                return @"uploading softdevice+bootloader ...";
            }
            return @"uploading softdevice ...";
            break;
            
        default:
            return @"uploading ...";
            break;
    }
}

-(NSString *)getInitPacketFileValidationMessage
{
    NSString *message;
    switch (self.enumFirmwareType) {
        case SOFTDEVICE:
            message = [NSString stringWithFormat:@"softdevice.dat is missing. It must be placed inside zip file with softdevice"];
            return message;
        case BOOTLOADER:
            message = [NSString stringWithFormat:@"bootloader.dat is missing. It must be placed inside zip file with bootloader"];
            return message;
        case APPLICATION:
            message = [NSString stringWithFormat:@"application.dat is missing. It must be placed inside zip file with application"];
            return message;
            
        case SOFTDEVICE_AND_BOOTLOADER:
            return @"system.dat is missing. It must be placed inside zip file with softdevice and bootloader";
            break;
            
        default:
            return @"Not valid File type";
            break;
    }
    
}

-(NSString *)getFileValidationMessage
{
    NSString *message;
    switch (self.enumFirmwareType) {
        case SOFTDEVICE:
            message = [NSString stringWithFormat:@"softdevice.hex not exist inside selected file %@",[self.selectedFileURL lastPathComponent]];
            return message;
        case BOOTLOADER:
            message = [NSString stringWithFormat:@"bootloader.hex not exist inside selected file %@",[self.selectedFileURL lastPathComponent]];
            return message;
        case APPLICATION:
            message = [NSString stringWithFormat:@"application.hex not exist inside selected file %@",[self.selectedFileURL lastPathComponent]];
            return message;
            
        case SOFTDEVICE_AND_BOOTLOADER:
            return @"For selected File Type, zip file is required having inside softdevice.hex and bootloader.hex";
            break;
            
        default:
            return @"Not valid File type";
            break;
    }
}

@end
