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

#import "DFUViewController.h"
#import "ScannerViewController.h"

#import "Constants.h"
#import "HelpViewController.h"
#import "FileTypeTableViewController.h"
#import "SSZipArchive.h"
#import "UnzipFirmware.h"
#import "Utility.h"
#import "DFUHelper.h"
#include "DFUHelper.h"


@interface DFUViewController () {
    
}

/*!
 * This property is set when the device has been selected on the Scanner View Controller.
 */
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
@property (strong, nonatomic) DFUOperations *dfuOperations;
@property (strong, nonatomic) DFUHelper *dfuHelper;

@property (weak, nonatomic) IBOutlet UILabel *fileName;
@property (weak, nonatomic) IBOutlet UILabel *fileSize;

@property (weak, nonatomic) IBOutlet UILabel *uploadStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectFileButton;
@property (weak, nonatomic) IBOutlet UIView *uploadPane;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UILabel *fileType;
@property (weak, nonatomic) IBOutlet UIButton *selectFileTypeButton;

@property BOOL isTransferring;
@property BOOL isTransfered;
@property BOOL isTransferCancelled;
@property BOOL isConnected;
@property BOOL isErrorKnown;

- (IBAction)uploadPressed;

@end

@implementation DFUViewController

@synthesize backgroundImage;
@synthesize deviceName;
@synthesize connectButton;
@synthesize selectedPeripheral;
@synthesize dfuOperations;
@synthesize fileName;
@synthesize fileSize;
@synthesize uploadStatus;
@synthesize progress;
@synthesize progressLabel;
@synthesize selectFileButton;
@synthesize uploadButton;
@synthesize uploadPane;
@synthesize fileType;
@synthesize selectedFileType;
@synthesize selectFileTypeButton;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        PACKETS_NOTIFICATION_INTERVAL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"dfu_number_of_packets"] intValue];
        NSLog(@"PACKETS_NOTIFICATION_INTERVAL %d",PACKETS_NOTIFICATION_INTERVAL);
        dfuOperations = [[DFUOperations alloc] initWithDelegate:self];
        self.dfuHelper = [[DFUHelper alloc] initWithData:dfuOperations];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
    
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0f, 0.0f), (float)(-M_PI / 2));
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    //if DFU peripheral is connected and user press Back button then disconnect it
    if ([self isMovingFromParentViewController] && self.isConnected) {
        NSLog(@"isMovingFromParentViewController");
        [dfuOperations cancelDFU];
    }
}

-(void)uploadPressed
{
    if (self.isTransferring) {
        [dfuOperations cancelDFU];
    }
    else {
        [self performDFU];
    }
}

-(void)performDFU
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self disableOtherButtons];
        uploadStatus.hidden = NO;
        progress.hidden = NO;
        progressLabel.hidden = NO;
        uploadButton.enabled = NO;
    });
    [self.dfuHelper checkAndPerformDFU];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' or 'select' seque will be performed only if DFU process has not been started or was completed.
    //return !self.isTransferring;
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        // controller.filterUUID = dfuServiceUUID; - the DFU service should not be advertised. We have to scan for any device hoping it supports DFU.
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"FileSegue"])
    {
        NSLog(@"performing Select File segue");
        UITabBarController *barController = segue.destinationViewController;
        NSLog(@"BarController %@",barController);
        UINavigationController *navController = [barController.viewControllers firstObject];
        NSLog(@"NavigationController %@",navController);
        AppFilesTableViewController *appFilesVC = (AppFilesTableViewController *)navController.topViewController;
        NSLog(@"AppFilesTableVC %@",appFilesVC);        
        appFilesVC.fileDelegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [Utility getDFUHelpText];
        helpVC.isDFUViewController = YES;
    }
    else if ([segue.identifier isEqualToString:@"FileTypeSegue"]) {
        NSLog(@"performing FileTypeSegue");
        FileTypeTableViewController *fileTypeVC = [segue destinationViewController];
        fileTypeVC.chosenFirmwareType = selectedFileType;
    }
}

- (void) clearUI
{
    selectedPeripheral = nil;
    deviceName.text = @"DEFAULT DFU";
    uploadStatus.text = @"waiting ...";
    uploadStatus.hidden = YES;
    progress.progress = 0.0f;
    progress.hidden = YES;
    progressLabel.hidden = YES;
    progressLabel.text = @"";
    [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
    uploadButton.enabled = NO;
    [self enableOtherButtons];
}

-(void)enableUploadButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (selectedFileType && self.dfuHelper.selectedFileSize > 0) {
            if ([self.dfuHelper isValidFileSelected]) {
                NSLog(@" valid file selected");
            }
            else {
                NSLog(@"Valid file not available in zip file");
                [Utility showAlert:[self.dfuHelper getFileValidationMessage]];
                return;
            }
        }
        if (self.dfuHelper.isDfuVersionExist) {
            if (selectedPeripheral && selectedFileType && self.dfuHelper.selectedFileSize > 0 && self.isConnected && self.dfuHelper.dfuVersion > 1) {
                if ([self.dfuHelper isInitPacketFileExist]) {
                    uploadButton.enabled = YES;
                }
                else {
                    [Utility showAlert:[self.dfuHelper getInitPacketFileValidationMessage]];
                }
            }
            else {
                NSLog(@"cant enable Upload button");
            }
        }
        else {
            if (selectedPeripheral && selectedFileType && self.dfuHelper.selectedFileSize > 0 && self.isConnected) {
                uploadButton.enabled = YES;
            }
            else {
                NSLog(@"cant enable Upload button");
            }
        }

    });
}

-(void)disableOtherButtons
{
    selectFileButton.enabled = NO;
    selectFileTypeButton.enabled = NO;
    connectButton.enabled = NO;
}

-(void)enableOtherButtons
{
    selectFileButton.enabled = YES;
    selectFileTypeButton.enabled = YES;
    connectButton.enabled = YES;
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterBackground");
    if (self.isConnected && self.isTransferring) {
        [Utility showBackgroundNotification:[self.dfuHelper getUploadStatusMessage]];
    }
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterForeground");
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark FileType Selector Delegate

- (IBAction)unwindFileTypeSelector:(UIStoryboardSegue*)sender
{
    FileTypeTableViewController *fileTypeVC = [sender sourceViewController];
    selectedFileType = fileTypeVC.chosenFirmwareType;
    NSLog(@"unwindFileTypeSelector, selected Filetype: %@",selectedFileType);
    fileType.text = selectedFileType;
    [self.dfuHelper setFirmwareType:selectedFileType];
    [self enableUploadButton];
}

#pragma mark Device Selection Delegate
-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    selectedPeripheral = peripheral;
    [dfuOperations setCentralManager:manager];
    deviceName.text = peripheral.name;
    [dfuOperations connectDevice:peripheral];
}

#pragma mark File Selection Delegate

-(void)onFileSelected:(NSURL *)url
{
    NSLog(@"onFileSelected");
    self.dfuHelper.selectedFileURL = url;
    if (self.dfuHelper.selectedFileURL) {
        NSLog(@"selectedFile URL %@",self.dfuHelper.selectedFileURL);
        NSString *selectedFileName = [[url path]lastPathComponent];
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        self.dfuHelper.selectedFileSize = fileData.length;
        NSLog(@"fileSelected %@",selectedFileName);
        
        //get last three characters for file extension
        NSString *extension = [selectedFileName substringFromIndex: [selectedFileName length] - 3];
        NSLog(@"selected file extension is %@",extension);
        if ([extension isEqualToString:@"zip"]) {
            NSLog(@"this is zip file");
            self.dfuHelper.isSelectedFileZipped = YES;
            self.dfuHelper.isManifestExist = NO;
            [self.dfuHelper unzipFiles:self.dfuHelper.selectedFileURL];
        }
        else {
            self.dfuHelper.isSelectedFileZipped = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            fileName.text = selectedFileName;
            fileSize.text = [NSString stringWithFormat:@"%lu bytes", (unsigned long)self.dfuHelper.selectedFileSize];
            [self enableUploadButton];
        });
    }
    else {
        [Utility showAlert:@"Selected file not exist!"];
    }
}


#pragma mark DFUOperations delegate methods

-(void)onDeviceConnected:(CBPeripheral *)peripheral
{
    NSLog(@"onDeviceConnected %@",peripheral.name);
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = NO;
    [self enableUploadButton];
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];

}

-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral
{
    NSLog(@"onDeviceConnectedWithVersion %@",peripheral.name);
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = YES;
    [self enableUploadButton];
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];

}

-(void)onDeviceDisconnected:(CBPeripheral *)peripheral
{
    NSLog(@"device disconnected %@",peripheral.name);
    self.isTransferring = NO;
    self.isConnected = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.dfuHelper.dfuVersion != 1) {
            [self clearUI];
        
            if (!self.isTransfered && !self.isTransferCancelled && !self.isErrorKnown) {
                if ([Utility isApplicationStateInactiveORBackground]) {
                    [Utility showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected.",peripheral.name]];
                }
                else {
                    [Utility showAlert:@"The connection has been lost"];
                }
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            }
            self.isTransferCancelled = NO;
            self.isTransfered = NO;
            self.isErrorKnown = NO;
        }
        else {
            double delayInSeconds = 3.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [dfuOperations connectDevice:peripheral];
            });
            
        }
    });
}

-(void)onReadDFUVersion:(int)version
{
    NSLog(@"onReadDFUVersion %d",version);
    self.dfuHelper.dfuVersion = version;
    NSLog(@"DFU Version: %d",self.dfuHelper.dfuVersion);
    if (self.dfuHelper.dfuVersion == 1) {
        [dfuOperations setAppToBootloaderMode];
    }
    [self enableUploadButton];
}

-(void)onDFUStarted
{
    NSLog(@"onDFUStarted");
    self.isTransferring = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        uploadButton.enabled = YES;
        [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        NSString *uploadStatusMessage = [self.dfuHelper getUploadStatusMessage];
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:uploadStatusMessage];
        }
        else {
            uploadStatus.text = uploadStatusMessage;
        }
    });
}

-(void)onDFUCancelled
{
    NSLog(@"onDFUCancelled");
    self.isTransferring = NO;
    self.isTransferCancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableOtherButtons];
    });
}

-(void)onSoftDeviceUploadStarted
{
    NSLog(@"onSoftDeviceUploadStarted");
}

-(void)onSoftDeviceUploadCompleted
{
    NSLog(@"onSoftDeviceUploadCompleted");
}

-(void)onBootloaderUploadStarted
{
    NSLog(@"onBootloaderUploadStarted");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:@"uploading bootloader ..."];
        }
        else {
            uploadStatus.text = @"uploading bootloader ...";
        }
    });
    
}

-(void)onBootloaderUploadCompleted
{
    NSLog(@"onBootloaderUploadCompleted");
}

-(void)onTransferPercentage:(int)percentage
{
    NSLog(@"onTransferPercentage %d",percentage);
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        progressLabel.text = [NSString stringWithFormat:@"%d %%", percentage];
        [progress setProgress:((float)percentage/100.0) animated:YES];
    });    
}

-(void)onSuccessfulFileTranferred
{
    NSLog(@"OnSuccessfulFileTransferred");
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isTransferring = NO;
        self.isTransfered = YES;
        NSString* message = [NSString stringWithFormat:@"%lu bytes transfered in %lu seconds", (unsigned long)dfuOperations.binFileSize, (unsigned long)dfuOperations.uploadTimeInSeconds];
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:message];
        }
        else {
            [Utility showAlert:message];
        }
        
    });
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"OnError %@",errorMessage);
    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Utility showAlert:errorMessage];
        [self clearUI];
    });
}

@end