//
//  DFUViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 10/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "DFUViewController.h"
#import "ScannerViewController.h"

#import "Constants.h"
#import "HelpViewController.h"
#import "FileTypeTableViewController.h"
#import "SSZipArchive.h"
#import "UnzipFirmware.h"
#import "Utility.h"

@interface DFUViewController () {
    
}

/*!
 * This property is set when the device has been selected on the Scanner View Controller.
 */
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
@property (nonatomic)DfuFirmwareTypes enumFirmwareType;

@property DFUOperations *dfuOperations;
@property NSURL *selectedFileURL;
@property NSURL *softdeviceURL;
@property NSURL *bootloaderURL;
@property NSURL *applicationURL;
@property NSUInteger selectedFileSize;


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
@property BOOL isSelectedFileZipped;

- (IBAction)uploadPressed;

@end

@implementation DFUViewController

@synthesize backgroundImage;
@synthesize verticalLabel;
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
@synthesize selectedFileURL;
@synthesize fileType;
@synthesize enumFirmwareType;
@synthesize selectedFileType;
@synthesize selectFileTypeButton;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        PACKETS_NOTIFICATION_INTERVAL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"dfu_number_of_packets"] intValue];
        NSLog(@"PACKETS_NOTIFICATION_INTERVAL %d",PACKETS_NOTIFICATION_INTERVAL);
        dfuOperations = [[DFUOperations alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
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
        [backgroundImage setImage:image];    }
    
    // Rotate the vertical label
    verticalLabel.transform = CGAffineTransformMakeRotation(-M_PI / 2);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (self.isSelectedFileZipped) {
        switch (enumFirmwareType) {
            case SOFTDEVICE_AND_BOOTLOADER:
                [dfuOperations performDFUOnFiles:self.softdeviceURL bootloaderURL:self.bootloaderURL firmwareType:SOFTDEVICE_AND_BOOTLOADER];
                break;
            case SOFTDEVICE:
                [dfuOperations performDFUOnFile:self.softdeviceURL firmwareType:SOFTDEVICE];
                break;
            case BOOTLOADER:
                [dfuOperations performDFUOnFile:self.bootloaderURL firmwareType:BOOTLOADER];
                break;
            case APPLICATION:
                [dfuOperations performDFUOnFile:self.applicationURL firmwareType:APPLICATION];
                break;
                
            default:
                NSLog(@"Not valid File type");
                break;
        }
    }
    else {
        [dfuOperations performDFUOnFile:selectedFileURL firmwareType:enumFirmwareType];
    }
}

-(void)unzipFiles:(NSURL *)zipFileURL
{
    self.softdeviceURL = self.bootloaderURL = self.applicationURL = nil;
    UnzipFirmware *unzipFiles = [[UnzipFirmware alloc]init];
    NSArray *firmwareFilesURL = [unzipFiles unzipFirmwareFiles:zipFileURL];
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
    }
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    //    UILocalNotification *notification = [[UILocalNotification alloc]init];
    //    notification.alertAction = @"Show";
    //    notification.alertBody = @"You are still connected to Running Speed and Cadence sensor. It will collect data also in background.";
    //    notification.hasAction = NO;
    //    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    //    notification.timeZone = [NSTimeZone  defaultTimeZone];
    //    notification.soundName = UILocalNotificationDefaultSoundName;
    //    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    //    [[UIApplication sharedApplication] cancelAllLocalNotifications];
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
    }
    else if ([segue.identifier isEqualToString:@"FileTypeSegue"]) {
        NSLog(@"performing FileTypeSegue");
        FileTypeTableViewController *fileTypeVC = [segue destinationViewController];
        fileTypeVC.chosenFirmwareType = selectedFileType;
    }
}

-(void) setFirmwareType:(NSString *)firmwareType
{
    if ([firmwareType isEqualToString:FIRMWARE_TYPE_SOFTDEVICE]) {
        enumFirmwareType = SOFTDEVICE;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_BOOTLOADER]) {
        enumFirmwareType = BOOTLOADER;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER]) {
        enumFirmwareType = SOFTDEVICE_AND_BOOTLOADER;
    }
    else if ([firmwareType isEqualToString:FIRMWARE_TYPE_APPLICATION]) {
        enumFirmwareType = APPLICATION;
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
        if (selectedFileType && self.selectedFileSize > 0) {
            if ([self isValidFileSelected]) {
                NSLog(@" valid file selected");
            }
            else {
                NSLog(@"Valid file not available in zip file");                
                //[self showAlert:[self getFileValidationMessage]];
                [Utility showAlert:[self getFileValidationMessage]];
                return;
            }
        }
        if (selectedPeripheral && selectedFileType && self.selectedFileSize > 0 && self.isConnected) {
            uploadButton.enabled = YES;
        }
        else {
            NSLog(@"cant enable Upload button");
        }

    });
}

-(BOOL)isValidFileSelected
{
    NSLog(@"isValidFileSelected");
    if (self.isSelectedFileZipped) {
        switch (enumFirmwareType) {
            case SOFTDEVICE_AND_BOOTLOADER:
                if (self.softdeviceURL && self.bootloaderURL) {
                    NSLog(@"Found Softdevice and Bootloader files in selected zip file");
                    return YES;
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
    else if(enumFirmwareType == SOFTDEVICE_AND_BOOTLOADER){
        NSLog(@"Please select zip file with softdevice and bootloader inside");
        return NO;
    }
    else {
        //Selcted file is not zip and file type is not Softdevice + Bootloader
        //then it is upto user to assign correct file to corresponding file type
        return YES;
    }    
}

/*-(void)showAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DFU" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}*/

-(NSString *)getUploadStatusMessage
{
    switch (enumFirmwareType) {
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
            return @"uploading softdevice ...";
            break;
            
        default:
            return @"uploading ...";
            break;
    }
}

-(NSString *)getFileValidationMessage
{
    NSString *message;
    switch (enumFirmwareType) {
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

#pragma mark FileType Selector Delegate

- (IBAction)unwindFileTypeSelector:(UIStoryboardSegue*)sender
{
    FileTypeTableViewController *fileTypeVC = [sender sourceViewController];
    selectedFileType = fileTypeVC.chosenFirmwareType;
    NSLog(@"unwindFileTypeSelector, selected Filetype: %@",selectedFileType);
    fileType.text = selectedFileType;
    [self setFirmwareType:selectedFileType];
    [self enableUploadButton];
}

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
    selectedFileURL = url;
    if (selectedFileURL) {
        NSLog(@"selectedFile URL %@",selectedFileURL);
        NSString *selectedFileName = [[url path]lastPathComponent];
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        self.selectedFileSize = fileData.length;
        NSLog(@"fileSelected %@",selectedFileName);
        
        //get last three characters for file extension
        NSString *extension = [selectedFileName substringFromIndex: [selectedFileName length] - 3];
        NSLog(@"selected file extension is %@",extension);
        if ([extension isEqualToString:@"zip"]) {
            NSLog(@"this is zip file");
            self.isSelectedFileZipped = YES;
            [self unzipFiles:selectedFileURL];
        }
        else {
            self.isSelectedFileZipped = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            fileName.text = selectedFileName;
            fileSize.text = [NSString stringWithFormat:@"%d bytes", self.selectedFileSize];
            [self enableUploadButton];
        });
    }
    else {
        //[self showAlert:@"Selected file not exist!"];
        [Utility showAlert:@"Selected file not exist!"];
    }
}


#pragma mark DFUOperations delegate methods

-(void)onDeviceConnected:(CBPeripheral *)peripheral
{
    NSLog(@"onDeviceConnected %@",peripheral.name);
    self.isConnected = YES;
    [self enableUploadButton];
}

-(void)onDeviceDisconnected:(CBPeripheral *)peripheral
{
    NSLog(@"device disconnected %@",peripheral.name);
    self.isTransferring = NO;
    self.isConnected = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearUI];
        if (!self.isTransfered && !self.isTransferCancelled && !self.isErrorKnown) {
            //[self showAlert:@"The connection has been lost"];
            [Utility showAlert:@"The connection has been lost"];
        }
        self.isTransferCancelled = NO;
        self.isTransfered = NO;
        self.isErrorKnown = NO;
    });
}

-(void)onDFUStarted
{
    NSLog(@"onDFUStarted");
    self.isTransferring = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        uploadButton.enabled = YES;
        [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        NSString *uploadStatusMessage = [self getUploadStatusMessage];
        uploadStatus.text = uploadStatusMessage;
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
        uploadStatus.text = @"uploading bootloader ...";
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
        NSString* message = [NSString stringWithFormat:@"%u bytes transfered in %u seconds", dfuOperations.binFileSize, dfuOperations.uploadTimeInSeconds];
        //[self showAlert:message];
        [Utility showAlert:message];
    });
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"OnError %@",errorMessage);
    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self showAlert:errorMessage];
        [Utility showAlert:errorMessage];
        [self clearUI];
    });
}

@end