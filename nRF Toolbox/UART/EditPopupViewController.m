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

#import "EditPopupViewController.h"

@interface EditPopupViewController ()



@end

@implementation EditPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isHidden) {
        [self.showHideButton setTitle:@"Show" forState:UIControlStateNormal];
    }
    else {
        [self.showHideButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    self.commandTextField.text = self.command;
    [self.iconButtons[self.iconIndex] setBackgroundColor:[UIColor grayColor]];
}

- (IBAction)okButtonPressed:(UIButton *)sender {
    NSLog(@"okButtonPressed");
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didButtonConfigured:self.command iconIndex:self.iconIndex shouldHideButton:self.isHidden];
}

- (IBAction)CancelButtonPressed:(UIButton *)sender {
    NSLog(@"cancelButtonPressed");
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)showHideButtonPressed:(UIButton *)sender {
    NSLog(@"showHideButtonPressed");
    if (self.isHidden) {
        self.isHidden = NO;
        [self.showHideButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    else {
        self.isHidden = YES;
        [self.showHideButton setTitle:@"Show" forState:UIControlStateNormal];
    }
}

- (IBAction)iconButtonPressed:(id)sender {
    NSLog(@"iconButtonPressed %ld",(long)[sender tag]);
    self.iconIndex = (int)[sender tag]-1;
    [self setSelectedButtonBackgroundColor];
}

-(void)setSelectedButtonBackgroundColor {
    for (UIButton *button in self.iconButtons) {
        [button setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:0.0f]];
    }
    [self.iconButtons[self.iconIndex] setBackgroundColor:[UIColor grayColor]];
}

#pragma mark - TextField editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldBeginEditing");
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn");
    [self.commandTextField resignFirstResponder];
    self.command = self.commandTextField.text;
    return YES;
}


@end
