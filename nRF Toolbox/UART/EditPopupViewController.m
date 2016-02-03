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

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray* iconButtons;
@property (weak, nonatomic) IBOutlet UIButton *showHideButton;
@property (weak, nonatomic) IBOutlet UITextField *commandTextField;

- (IBAction)showHideButtonPressed:(UIButton *)sender;
- (IBAction)okButtonPressed:(UIButton *)sender;
- (IBAction)CancelButtonPressed:(UIButton *)sender;

@end

@implementation EditPopupViewController

@synthesize showHideButton;
@synthesize iconButtons;
@synthesize commandTextField;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isHidden)
    {
        [showHideButton setTitle:@"Show" forState:UIControlStateNormal];
    }
    else
    {
        [showHideButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    
    commandTextField.text = self.command;
    commandTextField.delegate = self;
    [iconButtons[self.iconIndex] setBackgroundColor:[UIColor colorWithRed:222.0f/255.0f green:74.0f/255.0f blue:19.0f/255.0f alpha:1.0f]];
}

- (IBAction)okButtonPressed:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didButtonConfigured:commandTextField.text iconIndex:self.iconIndex shouldHideButton:self.isHidden];
}

- (IBAction)CancelButtonPressed:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showHideButtonPressed:(UIButton *)sender
{
    if (self.isHidden)
    {
        self.isHidden = NO;
        [self.showHideButton setTitle:@"Hide" forState:UIControlStateNormal];
    }
    else
    {
        self.isHidden = YES;
        [self.showHideButton setTitle:@"Show" forState:UIControlStateNormal];
    }
}

- (IBAction)iconButtonPressed:(id)sender
{
    self.iconIndex = (int)[sender tag] - 1;
    [self setSelectedButtonBackgroundColor];
}

-(void)setSelectedButtonBackgroundColor
{
    for (UIButton *button in self.iconButtons)
    {
        [button setBackgroundColor:[UIColor colorWithRed:127/255.0f green:127/255.0f blue:127/255.0f alpha:1.0f]];
    }
    [iconButtons[self.iconIndex] setBackgroundColor:[UIColor colorWithRed:222.0f/255.0f green:74.0f/255.0f blue:19.0f/255.0f alpha:1.0f]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
