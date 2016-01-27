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
#import "AppFilesViewController.h"
#import "UserFilesViewController.h"
#import "SSZipArchive.h"
#import "UnzipFirmware.h"
#import "Utility.h"
#import "DFUHelper.h"

@interface DFUViewController ()

/*!
 * This property is set when the device has been selected on the Scanner View Controller.
 */
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
@property (strong, nonatomic) DFUOperations *dfuOperations;
@property (strong, nonatomic) DFUHelper *dfuHelper;
@property (strong, nonatomic) NSString *selectedFileType;

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
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property BOOL isTransferring;
@property BOOL isTransfered;
@property BOOL isTransferCancelled;
@property BOOL isConnected;
@property BOOL isErrorKnown;

- (IBAction)uploadPressed;
- (IBAction)aboutButtonClicked:(id)sender;

@end

@implementation DFUViewController

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
    if (self)
    {
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
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0f, 0.0f), (float)(-M_PI / 2));
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    //if DFU peripheral is connected and user press Back button then disconnect it
    if ([self isMovingFromParentViewController] && self.isConnected)
    {
        [dfuOperations cancelDFU];
        [NSThread sleepForTimeInterval:1.0f];
    }
}

-(void)uploadPressed
{
    if (self.isTransferring)
    {
        [dfuOperations cancelDFU];
    }
    else
    {
        [self performDFU];
    }
}

- (IBAction)aboutButtonClicked:(id)sender {
    [self showAbout:[Utility getDFUHelpText]];
}

-(void)performDFU
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self disableOtherButtons];
        uploadStatus.text = @"Starting DFU...";
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
        UINavigationController *nc = segue.destinationViewController;
        ScannerViewController *controller = (ScannerViewController *)nc.childViewControllerForStatusBarHidden;
        //controller.filterUUID = dfuServiceUUID; - the DFU service should not be advertised. We have to scan for any device hoping it supports DFU.
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"FileSegue"])
    {
        UINavigationController* nc = segue.destinationViewController;
        UITabBarController *barController = (UITabBarController*) nc.childViewControllerForStatusBarHidden;
        AppFilesViewController *appFilesVC = [barController.viewControllers firstObject];
        appFilesVC.fileDelegate = self;
        UserFilesViewController* userFilesVC = [barController.viewControllers lastObject];
        userFilesVC.fileDelegate = self;
                
        if (self.dfuHelper.selectedFileURL)
        {
            NSString *path = [self.dfuHelper.selectedFileURL path];
            appFilesVC.selectedPath = path;
            userFilesVC.selectedPath = path;
        }
    }
}

- (void) clearUI
{
    selectedPeripheral = nil;
    deviceName.text = @"DEFAULT DFU";
    uploadStatus.text = @"Waiting...";
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
        if (selectedFileType && self.dfuHelper.selectedFileSize > 0)
        {
            if ([self.dfuHelper isValidFileSelected])
            {
                NSLog(@"Valid file selected");
            }
            else
            {
                NSLog(@"Valid file not available in zip file");
                [Utility showAlert:[self.dfuHelper getFileValidationMessage]];
                return;
            }
        }
        
        if (self.dfuHelper.isDfuVersionExist)
        {
            if (selectedPeripheral && selectedFileType && self.dfuHelper.selectedFileSize > 0 && self.isConnected && self.dfuHelper.dfuVersion > 1)
            {
                if ([self.dfuHelper isInitPacketFileExist])
                {
                    uploadButton.enabled = YES;
                }
                else
                {
                    [Utility showAlert:[self.dfuHelper getInitPacketFileValidationMessage]];
                }
            }
            else
            {
                if (selectedPeripheral && self.isConnected && self.dfuHelper.dfuVersion < 1)
                {
                    uploadStatus.text = [NSString stringWithFormat:@"Unsupported DFU version: %d", self.dfuHelper.dfuVersion];
                }
                NSLog(@"Can't enable Upload button");
            }
        }
        else
        {
            if (selectedPeripheral && selectedFileType && self.dfuHelper.selectedFileSize > 0 && self.isConnected)
            {
                uploadButton.enabled = YES;
            }
            else
            {
                NSLog(@"Can't enable Upload button");
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
    if (self.isConnected && self.isTransferring)
    {
        [Utility showBackgroundNotification:[self.dfuHelper getUploadStatusMessage]];
    }
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark Device Selection Delegate

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    selectedPeripheral = peripheral;
    [dfuOperations setCentralManager:manager];
    deviceName.text = peripheral.name;
    [dfuOperations connectDevice:peripheral];
    
    uploadStatus.text = @"Verifying device...";
    uploadStatus.hidden = NO;
}

#pragma mark File Selection Delegate

-(void)onFileSelected:(NSURL *)url
{
    // Reset the file type. A new file has been selected
    [self onFileTypeNotSelected];
    
    // Save the URL in DFU helper
    self.dfuHelper.selectedFileURL = url;
    
    if (self.dfuHelper.selectedFileURL) {
        NSMutableArray *availableTypes = [[NSMutableArray alloc] initWithCapacity:4];
        
        // Read file name and size
        NSString *selectedFileName = [[url path] lastPathComponent];
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        self.dfuHelper.selectedFileSize = fileData.length;
        
        // Get last three characters for file extension
        NSString *extension = [[selectedFileName substringFromIndex: [selectedFileName length] - 3] lowercaseString];
        if ([extension isEqualToString:@"zip"])
        {
            self.dfuHelper.isSelectedFileZipped = YES;
            self.dfuHelper.isManifestExist = NO;
            // Unzip the file. It will parse the Manifest file, if such exist, and assign firmware URLs
            [self.dfuHelper unzipFiles:url];
            
            // Manifest file has been parsed, we can now determine the file type based on its content
            // If a type is clear (only one bin/hex file) - just select it. Otherwise give user a change to select
            NSString* type = nil;
            if (((self.dfuHelper.softdevice_bootloaderURL && !self.dfuHelper.softdeviceURL && !self.dfuHelper.bootloaderURL) ||
                 (self.dfuHelper.softdeviceURL && self.dfuHelper.bootloaderURL && !self.dfuHelper.softdevice_bootloaderURL)) &&
                 !self.dfuHelper.applicationURL)
            {
                type = FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER;
            }
            else if (self.dfuHelper.softdeviceURL && !self.dfuHelper.bootloaderURL && !self.dfuHelper.applicationURL && !self.dfuHelper.softdevice_bootloaderURL)
            {
                type = FIRMWARE_TYPE_SOFTDEVICE;
            }
            else if (self.dfuHelper.bootloaderURL && !self.dfuHelper.softdeviceURL && !self.dfuHelper.applicationURL && !self.dfuHelper.softdevice_bootloaderURL)
            {
                type = FIRMWARE_TYPE_BOOTLOADER;
            }
            else if (self.dfuHelper.applicationURL && !self.dfuHelper.softdeviceURL && !self.dfuHelper.bootloaderURL && !self.dfuHelper.softdevice_bootloaderURL)
            {
                type = FIRMWARE_TYPE_APPLICATION;
            }
            
            // The type has been established?
            if (type)
            {
                // This will set the selectedFileType property
                [self onFileTypeSelected:type];
            }
            else
            {
                if (self.dfuHelper.softdeviceURL)
                {
                    [availableTypes addObject:FIRMWARE_TYPE_SOFTDEVICE];
                }
                if (self.dfuHelper.bootloaderURL)
                {
                    [availableTypes addObject:FIRMWARE_TYPE_BOOTLOADER];
                }
                if (self.dfuHelper.applicationURL)
                {
                    [availableTypes addObject:FIRMWARE_TYPE_APPLICATION];
                }
                if (self.dfuHelper.softdevice_bootloaderURL)
                {
                    [availableTypes addObject:FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER];
                }
            }
        }
        else
        {
            // If a HEX/BIN file has been selected user needs to choose the type manually
            self.dfuHelper.isSelectedFileZipped = NO;
            [availableTypes addObjectsFromArray:@[FIRMWARE_TYPE_SOFTDEVICE, FIRMWARE_TYPE_BOOTLOADER, FIRMWARE_TYPE_APPLICATION, FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER]];
        }
        
        // Update UI
        fileName.text = selectedFileName;
        fileSize.text = [NSString stringWithFormat:@"%lu bytes", (unsigned long)self.dfuHelper.selectedFileSize];
        
        // The File Type selection screen can be ommited it the type has been determined from the manifest file
        if (!selectedFileType)
        {
            // Show view to select the file type
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *nc = (UINavigationController *) [mainStoryboard instantiateViewControllerWithIdentifier:@"SelectFileType"];
            FileTypeViewController *fileTypeVC = (FileTypeViewController *) nc.childViewControllerForStatusBarHidden;
            fileTypeVC.options = availableTypes;
            fileTypeVC.delegate = self;
            [self presentViewController:nc animated:YES completion:nil];
        }
    }
    else
    {
        [Utility showAlert:@"Selected file doesn't exist!"];
    }
}

-(void)onFileTypeSelected:(NSString *)type
{
    selectedFileType = type;
    fileType.text = selectedFileType;
    if (type)
    {
        [self.dfuHelper setFirmwareType:selectedFileType];
        [self enableUploadButton];
    }
}

-(void)onFileTypeNotSelected
{
    self.dfuHelper.selectedFileURL = nil;
    fileName.text = nil;
    fileSize.text = nil;
    [self onFileTypeSelected:nil];
}

#pragma mark DFUOperations delegate methods

-(void)onDeviceConnected:(CBPeripheral *)peripheral
{
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = NO;
    [self enableUploadButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        uploadStatus.text = @"Device ready";
    });
    
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)])
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral
{
    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = YES;
    [self enableUploadButton];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        uploadStatus.text = @"Reading DFU version...";
    });
    
    //Following if condition display user permission alert for background notification
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)onDeviceDisconnected:(CBPeripheral *)peripheral
{
    self.isTransferring = NO;
    self.isConnected = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.dfuHelper.dfuVersion != 1)
        {
            [self clearUI];
        
            if (!self.isTransfered && !self.isTransferCancelled && !self.isErrorKnown)
            {
                if ([Utility isApplicationStateInactiveORBackground])
                {
                    [Utility showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected.",peripheral.name]];
                }
                else
                {
                    [Utility showAlert:@"The connection has been lost"];
                }
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            }
            self.isTransferCancelled = NO;
            self.isTransfered = NO;
            self.isErrorKnown = NO;
        }
        else
        {
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
    self.dfuHelper.dfuVersion = version;
    NSLog(@"DFU Version: %d",self.dfuHelper.dfuVersion);
    if (self.dfuHelper.dfuVersion == 1)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            uploadStatus.text = @"Switching to DFU mode...";
        });
        [dfuOperations setAppToBootloaderMode];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            uploadStatus.text = @"Device ready";
        });
        [self enableUploadButton];
    }
}

-(void)onDFUStarted
{
    NSLog(@"DFU Started");
    self.isTransferring = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        uploadButton.enabled = YES;
        [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        NSString *uploadStatusMessage = [self.dfuHelper getUploadStatusMessage];
        if ([Utility isApplicationStateInactiveORBackground])
        {
            [Utility showBackgroundNotification:uploadStatusMessage];
        }
        else
        {
            uploadStatus.text = uploadStatusMessage;
        }
    });
}

-(void)onDFUCancelled
{
    NSLog(@"DFU Cancelled");
    self.isTransferring = NO;
    self.isTransferCancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableOtherButtons];
    });
}

-(void)onSoftDeviceUploadStarted
{
    NSLog(@"SoftDevice Upload Started");
}

-(void)onSoftDeviceUploadCompleted
{
    NSLog(@"SoftDevice Upload Completed");
}

-(void)onBootloaderUploadStarted
{
    NSLog(@"Bootloader Upload Started");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([Utility isApplicationStateInactiveORBackground])
        {
            [Utility showBackgroundNotification:@"Uploading bootloader..."];
        }
        else
        {
            uploadStatus.text = @"Uploading bootloader...";
        }
    });
}

-(void)onBootloaderUploadCompleted
{
    NSLog(@"Bootloader Upload Completed");
}

-(void)onTransferPercentage:(int)percentage
{
    NSLog(@"Transfer progress: %d%%",percentage);
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        progressLabel.text = [NSString stringWithFormat:@"%d%%", percentage];
        [progress setProgress:((float)percentage/100.0) animated:YES];
    });    
}

-(void)onSuccessfulFileTranferred
{
    NSLog(@"File Transferred");
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isTransferring = NO;
        self.isTransfered = YES;
        NSString* message = [NSString stringWithFormat:@"%lu bytes transfered in %lu seconds", (unsigned long)dfuOperations.binFileSize, (unsigned long)dfuOperations.uploadTimeInSeconds];
        
        if ([Utility isApplicationStateInactiveORBackground])
        {
            [Utility showBackgroundNotification:message];
        }
        else
        {
            [Utility showAlert:message];
        }
    });
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"Error: %@", errorMessage);
    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Utility showAlert:errorMessage];
        [self clearUI];
    });
}

@end