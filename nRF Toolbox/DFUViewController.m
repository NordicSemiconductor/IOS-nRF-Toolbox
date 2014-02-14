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

@interface DFUViewController () {
    CBUUID *dfuServiceUUID;
    CBUUID *dfuControlPointCharacteristicUUID;
    CBUUID *dfuPacketCharacteristicUUID;
}

/*!
 * This property is set when the device has been selected on the Scanner View Controller.
 */
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;

@property DFUController *dfuController;
@property (weak, nonatomic) IBOutlet UILabel *fileName;
@property (weak, nonatomic) IBOutlet UILabel *fileSize;
@property (weak, nonatomic) IBOutlet UILabel *fileStatus;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectFileButton;
@property (weak, nonatomic) IBOutlet UIView *uploadPane;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

@property BOOL isTransferring;

- (IBAction)uploadPressed;

@end

@implementation DFUViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize deviceName;
@synthesize connectButton;
@synthesize selectedPeripheral;
@synthesize dfuController;
@synthesize fileName;
@synthesize fileSize;
@synthesize fileStatus;
@synthesize status;
@synthesize progress;
@synthesize progressLabel;
@synthesize selectFileButton;
@synthesize uploadButton;
@synthesize uploadPane;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        dfuServiceUUID = [CBUUID UUIDWithString:dfuServiceUUIDString];
        dfuControlPointCharacteristicUUID = [CBUUID UUIDWithString:dfuControlPointCharacteristicUUIDString];
        dfuPacketCharacteristicUUID = [CBUUID UUIDWithString:dfuPacketCharacteristicUUIDString];
        
        dfuController = [[DFUController alloc] initWithDelegate:self];
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
    
    // If firmware URL has been set by AppDelegate, show file information
    if (dfuController.appSize > 0)
    {
        fileName.text = dfuController.appName;
        fileSize.text = [NSString stringWithFormat:@"%ld bytes", dfuController.appSize];
        fileStatus.text = @"OK";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)uploadPressed
{
    if (!self.isTransferring)
    {
        [bluetoothManager connectPeripheral:selectedPeripheral options:nil];
        
        // Animate the pane size
        CGRect newSize = CGRectMake(35.0, 228.0, 251.0, 96.0);
        [UIView animateWithDuration:0.4
                delay:0.0
                options:UIViewAnimationOptionCurveEaseIn
                animations:^{
                    uploadPane.frame = newSize;
                } completion:^(BOOL finished) {
                    status.hidden = NO;
                    progress.hidden = NO;
                    progressLabel.hidden = NO;

                }];
    }
    else
    {
        [dfuController cancelTransfer];
    }
}

-(void)fileSelected:(NSURL *)url
{
    [dfuController setFirmwareURL:url];
    fileName.text = dfuController.appName;
    fileSize.text = [NSString stringWithFormat:@"%ld bytes", dfuController.appSize];
    fileStatus.text = @"OK";
    
    // If device has been selected before, allow upload
    if (selectedPeripheral != nil)
    {
        uploadButton.enabled = YES;
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
    return !self.isTransferring;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = dfuServiceUUID;
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"select"])
    {
        SelectorViewController *controller = (SelectorViewController *)segue.destinationViewController;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"-The Device Firmware Update (DFU) app that is compatible with Nordic Semiconductor nRF51822 devices that have the S110 SoftDevice and bootloader enabled.\n\n-It allows to upload new application onto the device over-the-air (OTA).\n\n-The DFU discovers supported DFU devices, connects to them, and uploads user selected firmware applications to the device.\n\n-Default number of Packet Receipt Notification is 10 but you can set up other number in the iPhone Settings."];
    }
}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;

    // Set the peripheral
    dfuController.peripheral = peripheral;
    selectedPeripheral = peripheral;
    deviceName.text = peripheral.name;
    
    if (dfuController.appSize > 0)
    {
        uploadButton.enabled = YES;
    }
}

#pragma mark Central Manager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        // TODO
    }
    else
    {
        // TODO
        NSLog(@"Bluetooth not ON");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Peripheral has connected. Discover required services
    [dfuController didConnect];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        selectedPeripheral = nil;
        
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Notify DFU controller about link loss
    [self.dfuController didDisconnect:error];
}

- (void) clearUI
{
    if (selectedPeripheral == nil)
    {
        deviceName.text = @"DEFAULT DFU";
    }
    status.text = @"";
    status.hidden = YES;
    progress.progress = 0.0f;
    progress.hidden = YES;
    progressLabel.hidden = YES;
    progressLabel.text = @"";
    selectFileButton.enabled = YES;
    [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
    uploadButton.enabled = selectedPeripheral != nil;   // TODO && aplikacja wybrana
    
    // Animate upload pane
    CGRect newSize = CGRectMake(35.0, 228.0, 251.0, 48.0);
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         uploadPane.frame = newSize;
                     } completion:^(BOOL finished) {
                         // empty
                     }];
}

#pragma mark DFU Controller delegate methods

-(void)didChangeState:(DFUControllerState) state;
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
}

@end