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

#import "UARTViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "HelpViewController.h"
#import "EditPopupViewController.h"
#import "LogViewController.h"

@interface UARTViewController ()
{
    CBUUID *UART_Service_UUID;
}

@end

@implementation UARTViewController

@synthesize connectButton;
@synthesize deviceName;

bool isRXCharacteristicFound = NO;
bool isUartPeripheralConnected = NO;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        UART_Service_UUID = [CBUUID UUIDWithString:uartServiceUUIDString];
        self.buttonIcons = @[@"Stop",@"Play",@"Pause",@"FastForward",@"Rewind",@"End",@"Start",@"Shuffle",@"Record",@"Number_1",
                             @"Number_2",@"Number_3",@"Number_4",@"Number_5",@"Number_6",@"Number_7",@"Number_8",@"Number_9",];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-20.0f, 0.0f), (float)(-M_PI / 2));
    self.uartLogText = [[NSMutableArray alloc]init];
    self.isEditMode = NO;
    
    //Set Normal Color to All Remote Buttons in Normal Mode
    [self setButtonsBackgroundColor];

    //Retrieve three arrays (icons names (NSString), commands (NSString), visibility(Bool)) from NSUserDefaults
    [self retrieveButtonsConfigurations];
}

#pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || isUartPeripheralConnected == NO;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        NSLog(@"prepareForSegue scan");
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = UART_Service_UUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"prepareForSegue help");
        HelpViewController *helpVC = (HelpViewController *)[segue destinationViewController];
        helpVC.helpText = [AppUtilities getUARTHelpText];
    }
    else if ([[segue identifier] isEqualToString:@"log"]) {
        NSLog(@"prepareForSegue log");
        LogViewController *logVC = (LogViewController *)[segue destinationViewController];
        logVC.logText = self.uartLogText;
        logVC.uartPeripheralName = self.uartPeripheralName;
        logVC.isRXCharacteristicFound = isRXCharacteristicFound;
        logVC.isUartPeripheralConnected = isUartPeripheralConnected;
    }
}

-(void)setButtonsBackgroundColor
{
    for (UIButton *button in self.buttons) {
        [button setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:156.0f/255.0f blue:222.0f/255.0f alpha:1.0f]];
    }
}

-(void)retrieveButtonsConfigurations
{
    NSUserDefaults *buttonsConfigurations = [NSUserDefaults standardUserDefaults];
    if ([buttonsConfigurations objectForKey:@"buttonsCommands"]) { //Buttons configurations already saved in NSUserDefaults
        NSLog(@"Buttons configurations already saved in NSUserDefaults");
        //retrieving the saved values
        self.buttonsCommands = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsCommands"]];
        self.buttonsHiddenStatus = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsHiddenStatus"]];
        self.buttonsImageNames = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsImageNames"]];
        [self showButtonsWithSavedConfiguration];
    }
    else { //First time viewcontroller is loaded and there is no saved buttons configurations in NSUserDefaults
        NSLog(@"First time viewcontroller is loaded and there is no saved buttons configurations in NSUserDefaults");
        //setting up the default values for the first time
        self.buttonsCommands = [[NSMutableArray alloc]initWithArray:@[@"Play",@"Stop",@"Pause",@"Rewind",@"Record",@"FastForward",@"Start",@"Shuffle",@"End"]];
        self.buttonsHiddenStatus = [[NSMutableArray alloc]initWithArray:@[@NO,@NO,@NO,@NO,@NO,@NO,@NO,@NO,@NO]];
        self.buttonsImageNames = [[NSMutableArray alloc]initWithArray:@[@"Play",@"Stop",@"Pause",@"Rewind",@"Record",@"FastForward",@"Start",@"Shuffle",@"End"]];
        
        [buttonsConfigurations setObject:self.buttonsCommands forKey:@"buttonsCommands"];
        [buttonsConfigurations setObject:self.buttonsHiddenStatus forKey:@"buttonsHiddenStatus"];
        [buttonsConfigurations setObject:self.buttonsImageNames forKey:@"buttonsImageNames"];
        [buttonsConfigurations synchronize];
    }
}

-(void)showButtonsWithSavedConfiguration
{
    NSLog(@"showButtonsWithSavedConfiguration");
    for (UIButton *button in self.buttons) {
        //set the buttons background color to some shade of Blue and icons
        [button setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:156.0f/255.0f blue:222.0f/255.0f alpha:1.0f]];
        UIImage *image = [UIImage imageNamed:self.buttonsImageNames[[button tag]-1]];
        [button setImage:image forState:UIControlStateNormal];
        //Show/Hide Buttons
        if ([self.buttonsHiddenStatus[[button tag]-1] boolValue]) {
            button.hidden = YES;
        }
        else {
            button.hidden = NO;
        }
    }
}

-(NSString *)showCurrentTime
{
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [outputFormatter stringFromDate:now];
    return timeString;
}

-(void)writeValueOnRX:(NSString *)value
{
    NSString *text;
    if (value.length != 0) {
        if (value.length > 20) {
            text = [value substringToIndex:20];
        }
        else {
            text = value;
        }
        if (isRXCharacteristicFound) {
            NSLog(@"writing command: %@ to UART peripheral: %@",text,self.uartPeripheralName);
            [self.uartBluetoothManager writeRXValue:text];
            [self addLogText:[NSString stringWithFormat:@"RX: %@",text]];
        }
    }
}

-(void)addLogText:(NSString *)logText
{
    [self.uartLogText addObject:[NSString stringWithFormat:@"[%@] %@",[self showCurrentTime],logText]];
}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    self.uartBluetoothManager = [BluetoothManager sharedInstance];
    [self.uartBluetoothManager setBluetoothCentralManager:manager];
    [self.uartBluetoothManager setUARTDelegate:self];
    [self.uartBluetoothManager connectDevice:peripheral];
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterBackground");
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ peripheral.",self.uartPeripheralName]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterForeground");
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (IBAction)connectOrDisconnectClicked:(UIButton *)sender {
    [self.uartBluetoothManager disconnectDevice];
}

#pragma mark - Remote Control Button Pressed

//One out of 9 Remote Buttons is pressed
- (IBAction)buttonPressed:(id)sender {
    NSLog(@"tag of buttonPressed: %ld",(long)[sender tag]);
    if (self.isEditMode) {
        self.selectedButton = (UIButton*)sender;
        [self showPopoverOnButton];
    }
    else {
        NSString *command = self.buttonsCommands[[sender tag]-1];
        [self writeValueOnRX:command];
    }
}

-(void)showPopoverOnButton
{
    EditPopupViewController *popoverVC = [self.storyboard instantiateViewControllerWithIdentifier:@"StoryboardIDEditPopup"];
    popoverVC.delegate = self;
    popoverVC.isHidden = [self.buttonsHiddenStatus[[self.selectedButton tag]-1 ] boolValue];
    popoverVC.command = self.buttonsCommands[[self.selectedButton tag]-1];
    NSString *buttonImageName = self.buttonsImageNames[[self.selectedButton tag] -1];
    popoverVC.iconIndex = (int)[self.buttonIcons indexOfObject:buttonImageName];
    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.popoverPresentationController.delegate = self;
    [self presentViewController:popoverVC animated:YES completion:nil];
    
    popoverVC.popoverPresentationController.sourceView = self.view;
    popoverVC.popoverPresentationController.sourceRect = self.view.bounds;
    [popoverVC.popoverPresentationController setPermittedArrowDirections:0];
    popoverVC.preferredContentSize = CGSizeMake(300.0, 300.0);
}

//Delegate of UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

//Delegate of ButtonConfigureDelegate is called when user will press OK button on EditPopupViewController
- (void) didButtonConfigured:(NSString*)command iconIndex:(int)index shouldHideButton:(BOOL)status {
    NSLog(@"didButtonConfigured: command %@, iconIndex %d, shouldHideButton %d",command,index,status);
    NSUserDefaults *buttonsConfigurations = [NSUserDefaults standardUserDefaults];
    int buttonTag = (int)[self.selectedButton tag] - 1;
    self.buttonsHiddenStatus[[self.selectedButton tag] - 1] = [NSNumber numberWithBool:status];
    [buttonsConfigurations setObject:self.buttonsHiddenStatus forKey:@"buttonsHiddenStatus"];
    if (index > 0) {
        UIImage *image = [UIImage imageNamed:self.buttonIcons[index]];
        [self.selectedButton setImage:image forState:UIControlStateNormal];
        NSString *selectedIconName = self.buttonIcons[index];
        self.buttonsImageNames[buttonTag] = selectedIconName;
        [buttonsConfigurations setObject:self.buttonsImageNames forKey:@"buttonsImageNames"];
    }
    if (![command isEqualToString:@""]) {
        // we subtract 1 from tag because tag start from 1 not from 0
        self.buttonsCommands[buttonTag] = command;
        NSLog(@"selcted Button command: %@",self.buttonsCommands[buttonTag]);
        [buttonsConfigurations setObject:self.buttonsCommands forKey:@"buttonsCommands"];
    }
    [buttonsConfigurations synchronize];
}

- (IBAction)editButtonPressed:(UIButton *)sender {
    NSLog(@"editButtonPressed");
    if (self.isEditMode) {
        //Editing Done, Normal Mode, Done pressed
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
        self.isEditMode = NO;
        //Set Normal Color to All Remote Buttons in Normal Mode
        for (UIButton *button in self.buttons) {
            [button setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:156.0f/255.0f blue:222.0f/255.0f alpha:1.0f]];
            //Show/Hide Button
            if ([self.buttonsHiddenStatus[[button tag]-1] boolValue]) {
                button.hidden = YES;
            }
            else {
                button.hidden = NO;
            }
        }
        
    }
    else {
        //Editing Start, Edit Mode, Edit Pressed
        [self.editButton setTitle:@"Done" forState:UIControlStateNormal];
        self.isEditMode = YES;
        //Set Orange Grey Color to all Remote Buttons in Edit Mode
        for (UIButton *button in self.buttons) {
            [button setBackgroundColor:[UIColor colorWithRed:222.0f/255.0f green:74.0f/255.0f blue:19.0f/255.0f alpha:1.0f]];
            button.hidden = NO;
        }
    }
}

#pragma mark BluetoothManager delegate methods

-(void)didDeviceConnected:(NSString *)peripheralName
{
    NSLog(@"onDeviceConnected %@",peripheralName);
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        self.uartPeripheralName = peripheralName;
        isUartPeripheralConnected = YES;
        [deviceName setText:self.uartPeripheralName];
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        [self addLogText:[NSString stringWithFormat:@"%@ is Connected",self.uartPeripheralName]];
    });
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

-(void)didDeviceDisconnected
{
    NSLog(@"UARTViewController: didDeviceDisconnected %@",self.uartPeripheralName);
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [deviceName setText:@"DEFAULT UART"];
        [self addLogText:[NSString stringWithFormat:@"%@ is Disconnected",self.uartPeripheralName]];
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected",self.uartPeripheralName]];
        }
        self.uartPeripheralName = nil;
        isRXCharacteristicFound = NO;
        isUartPeripheralConnected = NO;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

-(void)didDiscoverUARTService:(CBService *)uartService
{
    NSLog(@"didDiscoverUARTService");
    [self addLogText:[NSString stringWithFormat:@"UART service is discovered"]];
}

-(void)didDiscoverRXCharacteristic:(CBCharacteristic *)rxCharacteristic
{
    NSLog(@"didDiscoverRXCharacteristic");
    isRXCharacteristicFound = YES;
    [self addLogText:[NSString stringWithFormat:@"UART RX characteristic is discovered"]];
}

-(void)didDiscoverTXCharacteristic:(CBCharacteristic *)txCharacteristic
{
    NSLog(@"didDiscoverTXCharacteristic");
    [self addLogText:[NSString stringWithFormat:@"UART TX characteristic is discovered"]];
}

-(void)didReceiveTXNotification:(NSData *)data
{
    NSString* text = [NSString stringWithUTF8String:[data bytes]];
    [self addLogText:[NSString stringWithFormat:@"TX: %@",text]];
}

-(void)didError:(NSString *)errorMessage
{
    NSLog(@"didError: %@",errorMessage);
}

@end
