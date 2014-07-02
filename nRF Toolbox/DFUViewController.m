//
//  DFUViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 10/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "DFUViewController.h"
#import "ScannerViewController.h"
#import "SelectorViewController.h"
#import "Constants.h"
#import "HelpViewController.h"
#import "FileTypeTableViewController.h"
#import "SSZipArchive.h"

@interface DFUViewController () {
    //CBUUID *dfuServiceUUID;
    //CBUUID *dfuControlPointCharacteristicUUID;
    //CBUUID *dfuPacketCharacteristicUUID;
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
@property NSURL *blinkyappURL;
@property NSUInteger selectedFileSize;

@property (weak, nonatomic) IBOutlet UILabel *fileName;
@property (weak, nonatomic) IBOutlet UILabel *fileSize;
@property (weak, nonatomic) IBOutlet UILabel *fileStatus;

@property (weak, nonatomic) IBOutlet UILabel *uploadStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectFileButton;
@property (weak, nonatomic) IBOutlet UIView *uploadPane;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UILabel *fileType;

@property BOOL isTransferring;
@property BOOL isTransfered;
@property BOOL isTransferCancelled;
@property BOOL isConnected;
@property BOOL isErrorKnown;
@property BOOL isSelectedFileZipped;

- (IBAction)uploadPressed;

@end

@implementation DFUViewController
//@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize deviceName;
@synthesize connectButton;
@synthesize selectedPeripheral;
@synthesize dfuOperations;
@synthesize fileName;
@synthesize fileSize;
@synthesize fileStatus;
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


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        /*dfuServiceUUID = [CBUUID UUIDWithString:dfuServiceUUIDString];
        dfuControlPointCharacteristicUUID = [CBUUID UUIDWithString:dfuControlPointCharacteristicUUIDString];
        dfuPacketCharacteristicUUID = [CBUUID UUIDWithString:dfuPacketCharacteristicUUIDString];*/
        
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
        [backgroundImage setImage:image];
    }
    
    // Rotate the vertical label
    verticalLabel.transform = CGAffineTransformMakeRotation(-M_PI / 2);
    /*if(!self.selectedFileType) {
        self.selectedFileType = [[Utility getFirmwareTypes]firstObject];
    }*/
    
    // If firmware URL has been set by AppDelegate, show file information
    /*if (dfuController.appSize > 0)
    {
        fileName.text = dfuController.appName;
        fileSize.text = [NSString stringWithFormat:@"%ld bytes", dfuController.appSize];
        fileStatus.text = @"OK";
    }*/
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
        uploadStatus.hidden = NO;
        progress.hidden = NO;
        progressLabel.hidden = NO;
        // Animate the pane size
        /*CGRect newSize = CGRectMake(35.0, 228.0, 251.0, 96.0);
        [UIView animateWithDuration:0.4
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             uploadPane.frame = newSize;
                         } completion:^(BOOL finished) {
                             uploadStatus.hidden = NO;
                             progress.hidden = NO;
                             progressLabel.hidden = NO;                             
                         }];*/
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
                [dfuOperations performDFUOnFile:self.blinkyappURL firmwareType:APPLICATION];
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

-(void)unzipFirmwareFiles
{
    NSLog(@"unzipFirmwareFiles");
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"firmware" ofType:@"zip"];
    NSString *outputPath = [self _cachesPath:@"unzipFiles"];
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:outputPath];
    NSLog(@"zipfile path: %@",zipPath);
    NSLog(@"unzip folder path: %@",outputPath);
    //path to softdevice
    NSString *softdevicePath = [outputPath stringByAppendingPathComponent:@"softdevice.hex"];
    NSString *bootloaderPath = [outputPath stringByAppendingPathComponent:@"bootloader.hex"];
    NSString *blinkyappPath = [outputPath stringByAppendingPathComponent:@"application.hex"];
    self.softdeviceURL = [NSURL fileURLWithPath:softdevicePath];
    self.bootloaderURL = [NSURL fileURLWithPath:bootloaderPath];
    self.blinkyappURL = [NSURL fileURLWithPath:blinkyappPath];
    
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
    else if ([segue.identifier isEqualToString:@"select"])
    {
        NSLog(@"performing Select File segue");
        SelectorViewController *controller = (SelectorViewController *)segue.destinationViewController;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"-The Device Firmware Update (DFU) app that is compatible with Nordic Semiconductor nRF51822 devices that have the S110 SoftDevice and bootloader enabled.\n\n-It allows to upload new application onto the device over-the-air (OTA).\n\n-The DFU discovers supported DFU devices, connects to them, and uploads user selected firmware applications to the device.\n\n-Default number of Packet Receipt Notification is 10 but you can set up other number in the iPhone Settings."];
    }
    else if ([segue.identifier isEqualToString:@"FileTypeSegue"]) {
        NSLog(@"performing FileTypeSegue");
        FileTypeTableViewController *fileTypeVC = [segue destinationViewController];
        fileTypeVC.chosenFirmwareType = selectedFileType;
    }
}

- (IBAction)unwindFileTypeSelector:(UIStoryboardSegue*)sender
{
    FileTypeTableViewController *fileTypeVC = [sender sourceViewController];
    selectedFileType = fileTypeVC.chosenFirmwareType;
    NSLog(@"unwindFileTypeSelector, selected Filetype: %@",selectedFileType);
    fileType.text = selectedFileType;
    [self setFirmwareType:selectedFileType];
    [self enableUploadButton];
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
    //fileStatus.text = @"";
    uploadStatus.hidden = YES;
    progress.progress = 0.0f;
    progress.hidden = YES;
    progressLabel.hidden = YES;
    progressLabel.text = @"";
    selectFileButton.enabled = YES;
    [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
    uploadButton.enabled = NO;
    
    // Animate upload pane
    /*CGRect newSize = CGRectMake(35.0, 228.0, 251.0, 48.0);
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         uploadPane.frame = newSize;
                     } completion:^(BOOL finished) {
                         // empty
    }];*/
}

-(void)enableUploadButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (selectedFileType && self.selectedFileSize > 0) {
            if ([self isValidFileSelected]) {
                NSLog(@" valid file selected");
                fileStatus.text = @"OK";
            }
            else {
                NSLog(@"Valid file not available in zip file");
                [self showAlert:@"Valid file not selected or not present"];
                fileStatus.text = @""; //choose some nice text here
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
    NSLog(@"checkValidFileSelected");
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
                if (self.blinkyappURL) {
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

-(void)showAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DFU" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

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

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    selectedPeripheral = peripheral;
    [dfuOperations setCentralManager:manager];
    deviceName.text = peripheral.name;
    [dfuOperations connectDevice:peripheral];
}

#pragma mark File Selector Delegate methods

-(void)fileSelected:(NSURL *)url
{
    selectedFileURL = url;
    if (selectedFileURL) {
        NSLog(@"selectedFile path %@",selectedFileURL);
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
            [self unzipFirmwareFiles];
        }
        else {
            self.isSelectedFileZipped = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            fileName.text = selectedFileName;
            fileSize.text = [NSString stringWithFormat:@"%d bytes", self.selectedFileSize];
            //fileStatus.text = @"OK";
            [self enableUploadButton];
            
        });
        
    }
    else {
        [self showAlert:@"Selected file not exist!"];
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
            [self showAlert:@"The connection has been lost"];
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
        if (enumFirmwareType == SOFTDEVICE_AND_BOOTLOADER) {
            NSString* messge = [NSString stringWithFormat:@"%d bytes transfered", dfuOperations.binFileSize+dfuOperations.binFileSize2];
            [self showAlert:messge];
        }
        else {
            NSString* messge = [NSString stringWithFormat:@"%d bytes transfered", dfuOperations.binFileSize];
            [self showAlert:messge];
        }
        
    });
    
    
    /*NSString* messge = [NSString stringWithFormat:@"%lu bytes transfered in %lu ms.", dfuController.binSize, (unsigned long) (dfuController.uploadInterval * 1000.0)];*/
    
}

-(void)onError:(NSString *)errorMessage
{
    NSLog(@"OnError %@",errorMessage);
    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlert:errorMessage];
        [self clearUI];
    });
    
}


/*-(void)didChangeState:(DFUControllerState) state;
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == IDLE)
        {
            self.isTransferring = YES;
            selectFileButton.enabled = NO;
            [dfuController startTransfer];
            [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        }
        status.text = [self.dfuController stringFromState:state];
    });
}

-(void)didUpdateProgress:(float)percent
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        progressLabel.text = [NSString stringWithFormat:@"%.0f %%", percent*100];
        [progress setProgress:percent animated:YES];
    });
}

-(void)didFinishTransfer
{
    NSLog(@"Transfer finished!");
    self.isTransferring = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        selectedPeripheral = nil;
        [self clearUI];
        
        NSString* messge = [NSString stringWithFormat:@"%lu bytes transfered in %lu ms.", dfuController.binSize, (unsigned long) (dfuController.uploadInterval * 1000.0)];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload completed" message:messge delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    });
}

-(void)didCancelTransfer
{
    NSLog(@"Transfer cancelled!");
    self.isTransferring = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearUI];
    });
}

-(void)didDisconnect:(NSError *)error
{
    NSLog(@"Transfer terminated!");
    self.isTransferring = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearUI];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The connection has been lost." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    });
}

-(void)didErrorOccurred:(DFUTargetResponse)error
{
    NSLog(@"Error occurred: %d", error);
    self.isTransferring = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* message = nil;
        switch (error)
        {
            case CRC_ERROR:
                message = @"CRC error";
                break;
                
            case DATA_SIZE_EXCEEDS_LIMIT:
                message = @"Data size exceeds limit";
                break;
                
            case INVALID_STATE:
                message = @"Device is in the invalid state";
                break;
                
            case NOT_SUPPORTED:
                message = @"Operation not supported. Image file may be to large.";
                break;
                
            case OPERATION_FAILED:
                message = @"Operation failed";
                break;
                
            case DEVICE_NOT_SUPPORTED:
                message = @"Device is not supported. Check if it is in the DFU state.";
                [bluetoothManager cancelPeripheralConnection:selectedPeripheral];
                selectedPeripheral = nil;
                break;
                
            default:
                break;
        }
        //
        [self clearUI];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    });
}*/

@end