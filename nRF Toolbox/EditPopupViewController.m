//
//  EditPopupViewController.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 28/05/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

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
