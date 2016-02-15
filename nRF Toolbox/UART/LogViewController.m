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
#import "LogItemCell.h"

@interface LogViewController ()

@property (weak, nonatomic) IBOutlet UITableView *displayLogTextTable;
@property (weak, nonatomic) IBOutlet UITextField *commandTextField;

@end

@implementation LogViewController

@synthesize displayLogTextTable;
@synthesize commandTextField;
@synthesize bluetoothManager;

NSMutableArray *logItems;

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        // Custom initialization
        logItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    displayLogTextTable.delegate = self;
    displayLogTextTable.dataSource = self;
    displayLogTextTable.rowHeight = UITableViewAutomaticDimension;
    displayLogTextTable.estimatedRowHeight = 25;
    [displayLogTextTable reloadData];
    
    commandTextField.placeholder = @"No UART connected";
    commandTextField.delegate = self;
}

-(void)scrollDisplayViewDown
 {
     @try {
         //scrolls the table view down when last log statement is below the bottom of tableview
         [displayLogTextTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[logItems count]-1 inSection:0]
                                    atScrollPosition:UITableViewScrollPositionBottom animated:YES];
     }
     @catch (NSException *exception) {
         NSLog(@"Exception!");
         // do nothing
     }
 }

-(void)log:(LogLevel)level message:(NSString *)message
{
    LogItem *item = [[LogItem alloc] init];
    item.level = level;
    item.message = message;
    item.timestamp = [self getCurrentTime];
    [logItems addObject:item];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [displayLogTextTable reloadData];
        [self scrollDisplayViewDown];
    });
}

-(NSString *)getCurrentTime
{
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *timeString = [outputFormatter stringFromDate:now];
    return timeString;
}

#pragma mark - TextField editing

-(void)setBluetoothManager:(BluetoothManager *)manager
{
    bluetoothManager = manager;
    
    if (manager)
    {
        commandTextField.placeholder = @"Write command";
        commandTextField.text = @"";
    }
    else
    {
        commandTextField.placeholder = @"No UART connected";
        commandTextField.text = @"";
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
 {
     //Only shows the keyboard when Uart peripheral is connected
     if (bluetoothManager) {
         return YES;
     }
     return NO;
}
     
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
     [self.commandTextField resignFirstResponder];
     [bluetoothManager send:self.commandTextField.text];
     self.commandTextField.text = @"";
     return YES;
 }

#pragma mark - TableView delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [logItems count];
 }
 
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"logCell"];
    LogItem *item = [logItems objectAtIndex:indexPath.row];
    
    [cell set:item];
    return cell;
}

@end
