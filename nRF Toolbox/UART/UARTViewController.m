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
#import "SWRevealViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "LogViewController.h"
#import "AppUtilities.h"
#import "EditPopupViewController.h"
#import "LogViewController.h"

@interface UARTViewController ()

@property (strong, nonatomic) BluetoothManager *bluetoothManager;

@property (strong, nonatomic) NSString *uartPeripheralName;
@property (strong, nonatomic) NSMutableArray *buttonsCommands;
@property (strong, nonatomic) NSMutableArray *buttonsHiddenStatus;
@property (strong, nonatomic) NSMutableArray *buttonsImageNames;

@property (strong, nonatomic) NSArray *buttonIcons;
@property (strong, nonatomic) UIButton *selectedButton;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray* buttons;

@property (nonatomic, weak) LogViewController* logger;
@property (nonatomic) BOOL editMode;

- (IBAction)editButtonPressed:(UIButton *)sender;
- (IBAction)connectOrDisconnectClicked:(UIButton *)sender;
- (IBAction)showLogButtonClidked:(id)sender;

@end

@implementation UARTViewController

@synthesize connectButton;
@synthesize deviceName;
@synthesize logger;

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        // Custom initialization
        self.buttonIcons = @[@"Stop",@"Play",@"Pause",@"FastForward",@"Rewind",@"End",@"Start",@"Shuffle",@"Record",@"Number_1",
                             @"Number_2",@"Number_3",@"Number_4",@"Number_5",@"Number_6",@"Number_7",@"Number_8",@"Number_9",];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Rotate the vertical label
    self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-20.0f, 0.0f), (float)(-M_PI / 2));
    
    // Retrieve three arrays (icons names (NSString), commands (NSString), visibility(Bool)) from NSUserDefaults
    [self retrieveButtonsConfigurations];
    self.editMode = NO;
    
    // Configure the SWRevealViewController
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
        logger = (LogViewController*) revealViewController.rearViewController;
    }
}

- (IBAction)showLogButtonClidked:(id)sender
{
    [self.revealViewController revealToggleAnimated:YES];
}

- (IBAction)editButtonPressed:(UIButton *)sender
{
    self.editMode = !self.editMode;
}

#pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if bluetoothManager == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || self.bluetoothManager == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        UINavigationController *nc = segue.destinationViewController;
        ScannerViewController *controller = (ScannerViewController *)nc.childViewControllerForStatusBarHidden;
        controller.delegate = self;
    }
}

#pragma mark - Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    self.bluetoothManager = [[BluetoothManager alloc] initWithManager: manager];
    self.bluetoothManager.delegate = self;
    self.bluetoothManager.logger = logger;
    
    [self.bluetoothManager connectDevice:peripheral];
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ peripheral.",self.uartPeripheralName]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (IBAction)connectOrDisconnectClicked:(UIButton *)sender {
    [self.bluetoothManager disconnectDevice];
}

#pragma mark - UART API

-(void)send:(NSString *)value
{
    if (self.bluetoothManager)
    {
        [self.bluetoothManager send:value];
    }
}

#pragma mark - Buttons behaviour

-(void)setEditMode:(BOOL)editMode
{
    _editMode = editMode;
    
    if (editMode)
    {
        [self.editButton setTitle:@"Done" forState:UIControlStateNormal];
        for (UIButton *button in self.buttons) {
            [button setBackgroundColor:[UIColor colorWithRed:222.0f/255.0f green:74.0f/255.0f blue:19.0f/255.0f alpha:1.0f]];
            [button setEnabled:YES];
        }
    }
    else
    {
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self showButtonsWithSavedConfiguration];
    }
}

-(void)retrieveButtonsConfigurations
{
    NSUserDefaults *buttonsConfigurations = [NSUserDefaults standardUserDefaults];
    
    if ([buttonsConfigurations objectForKey:@"buttonsCommands"]) //Buttons configurations already saved in NSUserDefaults
    {
        // Retrieving the saved values
        self.buttonsCommands = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsCommands"]];
        self.buttonsHiddenStatus = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsHiddenStatus"]];
        self.buttonsImageNames = [NSMutableArray arrayWithArray:[buttonsConfigurations objectForKey:@"buttonsImageNames"]];
        [self showButtonsWithSavedConfiguration];
    }
    else //First time viewcontroller is loaded and there is no saved buttons configurations in NSUserDefaults
    {
        // Setting up the default values for the first time
        self.buttonsCommands = [[NSMutableArray alloc]initWithArray:@[@"",@"",@"",@"",@"",@"",@"",@"",@""]];
        self.buttonsHiddenStatus = [[NSMutableArray alloc]initWithArray:@[@YES,@YES,@YES,@YES,@YES,@YES,@YES,@YES,@YES]];
        self.buttonsImageNames = [[NSMutableArray alloc]initWithArray:@[@"Play",@"Play",@"Play",@"Play",@"Play",@"Play",@"Play",@"Play",@"Play"]];
        
        [buttonsConfigurations setObject:self.buttonsCommands forKey:@"buttonsCommands"];
        [buttonsConfigurations setObject:self.buttonsHiddenStatus forKey:@"buttonsHiddenStatus"];
        [buttonsConfigurations setObject:self.buttonsImageNames forKey:@"buttonsImageNames"];
        [buttonsConfigurations synchronize];
    }
}

-(void)showButtonsWithSavedConfiguration
{
    for (UIButton *button in self.buttons)
    {
        if ([self.buttonsHiddenStatus[[button tag]-1] boolValue])
        {
            [button setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]];
            [button setImage:nil forState:UIControlStateNormal];
            [button setEnabled:NO];
        }
        else
        {
            [button setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:156.0f/255.0f blue:222.0f/255.0f alpha:1.0f]];
            UIImage *image = [UIImage imageNamed:self.buttonsImageNames[[button tag]-1]];
            [button setImage:image forState:UIControlStateNormal];
            [button setEnabled:YES];
        }
    }
}

#pragma mark - Edit action handling

//One out of 9 Remote Buttons is pressed
- (IBAction)buttonPressed:(id)sender
{
    if (self.editMode)
    {
        self.selectedButton = (UIButton*)sender;
        [self showPopoverOnButton];
    }
    else
    {
        NSString *command = self.buttonsCommands[[sender tag]-1];
        [self send:command];
    }
}

-(void)showPopoverOnButton
{
    EditPopupViewController *popoverVC = [self.storyboard instantiateViewControllerWithIdentifier:@"StoryboardIDEditPopup"];
    popoverVC.delegate = self;
    popoverVC.isHidden = NO; //[self.buttonsHiddenStatus[[self.selectedButton tag]-1 ] boolValue]; // Show it when the popover opens
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
    NSUserDefaults *buttonsConfigurations = [NSUserDefaults standardUserDefaults];
    
    int buttonTag = (int)[self.selectedButton tag] - 1;
    
    self.buttonsHiddenStatus[[self.selectedButton tag] - 1] = [NSNumber numberWithBool:status];
    [buttonsConfigurations setObject:self.buttonsHiddenStatus forKey:@"buttonsHiddenStatus"];
    
    if (!status)
    {
        UIImage *image = [UIImage imageNamed:self.buttonIcons[index]];
        [self.selectedButton setImage:image forState:UIControlStateNormal];
    }
    else
    {
        [self.selectedButton setImage:nil forState:UIControlStateNormal];
    }
    
    self.buttonsImageNames[buttonTag] = self.buttonIcons[index];
    [buttonsConfigurations setObject:self.buttonsImageNames forKey:@"buttonsImageNames"];
    
    self.buttonsCommands[buttonTag] = command;
    [buttonsConfigurations setObject:self.buttonsCommands forKey:@"buttonsCommands"];
    
    [buttonsConfigurations synchronize];
}

#pragma mark - BluetoothManager delegate methods

-(void)didDeviceConnected:(NSString *)peripheralName
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        logger.bluetoothManager = self.bluetoothManager;
        self.uartPeripheralName = peripheralName;
        [deviceName setText:peripheralName];
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
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
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        logger.bluetoothManager = nil;
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        [deviceName setText:@"DEFAULT UART"];
        
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected", self.uartPeripheralName]];
        }
        self.uartPeripheralName = nil;
        
    });
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.bluetoothManager = nil;
}

-(void)isDeviceReady
{
    NSLog(@"Device is ready");
}

-(void)deviceNotSupported
{
    NSLog(@"Device not supported");
}

@end
