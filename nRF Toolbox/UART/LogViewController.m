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

#import "LogViewController.h"
#import "BluetoothManager.h"

@interface LogViewController ()

@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.displayLogTextTable.delegate = self;
    self.displayLogTextTable.dataSource = self;
    self.commandTextField.placeholder = @"No UART connected";
    [self setup];
}

-(void) setup
{
    //if there is any log statement exist then reload table
    if ([self.logText count] > 0) {
        [self.displayLogTextTable reloadData];
        [self scrollDisplayViewDown];
    }
    //if uart peripheral is connected then get the BluetoothManager class sharedInstance
    //also subscribe for two observers to receive TX notification and peripheral disconnection message
    if (self.isUartPeripheralConnected) {
        NSLog(@"sent peripheral is connected");
        self.uartBluetoothManager = [BluetoothManager sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeviceDisconnected) name:@"CBPeripheralDisconnectNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveTXNotification) name:@"CBPeripheralTXNotification" object:nil];
        self.commandTextField.placeholder = @"Type Command";
    }

}

- (void)dealloc
{
    //Unsubscribe to both notifications
    NSLog(@"LogViewController: dealloc, Removing observer");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CBPeripheralDisconnectNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CBPeripheralTXNotification" object:nil];
}

-(void)scrollDisplayViewDown
 {
     //scrolls the table view down when last log statement is below the bottom of tableview
     NSLog(@"scrollDisplayViewDown");
     [self.displayLogTextTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.logText count]-1 inSection:0]
                                     atScrollPosition:UITableViewScrollPositionBottom animated:YES];
 }

#pragma mark - TextField editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
 {
     NSLog(@"textFieldShouldBeginEditing");
     //Only shows the keyboard when Uart peripheral is connected
     if (self.isUartPeripheralConnected) {
         return YES;
     }
     return NO;
}
     
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
     NSLog(@"textFieldShouldReturn");
     [self.commandTextField resignFirstResponder];
     [self writeValueOnRX:self.commandTextField.text];
     self.commandTextField.text = @"";
     return YES;
 }

#pragma mark - Tableview delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.logText count];
 }
 
 -(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"logCell"];
     if (cell == nil) {
         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"logCell"];
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
     }
     cell.textLabel.font  = [ UIFont fontWithName: @"Arial" size: 12.0 ];
     cell.textLabel.text = [self.logText objectAtIndex:indexPath.row];
     return cell;
 }
 
 -(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
     return 20.0;
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
        //if text types is greater than 20 characters the extract the first 20 characters
        if (value.length > 20) {
            text = [value substringToIndex:20];
        }
        else {
            text = value;
        }
        if (self.isRXCharacteristicFound) {
            NSLog(@"writing command: %@ to UART peripheral: %@",text,self.uartPeripheralName);
            [self.uartBluetoothManager writeRXValue:text];
            [self addLogText:[NSString stringWithFormat:@"RX: %@",text]];
        }
    }
}

-(void)addLogText:(NSString *)logText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logText addObject:[NSString stringWithFormat:@"[%@] %@",[self showCurrentTime],logText]];
        [self.displayLogTextTable reloadData];
        [self scrollDisplayViewDown];
    });    
}

-(void)didDeviceDisconnected
{
    NSLog(@"Received Notifictaion, LogViewController: didDeviceDisconnected");
    self.uartPeripheralName = nil;
    self.isRXCharacteristicFound = NO;
    self.isUartPeripheralConnected = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.commandTextField.placeholder = @"No UART connected";
    });
    [self refreshTableAfterDelay];
}

-(void)didReceiveTXNotification
{
    NSLog(@"Received Notification, LogViewController: didReceiveTXNotification");
    [self refreshTableAfterDelay];
}

-(void)refreshTableAfterDelay
{
    //One second delay because Log table datasource is updated in UARTViewController
    double delayInSeconds = 1.0;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        [self.displayLogTextTable reloadData];
        [self scrollDisplayViewDown];
    });
}


@end
