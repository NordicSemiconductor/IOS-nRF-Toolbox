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

#import <UIKit/UIKit.h>


@protocol ButtonConfigureDelegate <NSObject>

- (void) didButtonConfigured:(NSString*)command iconIndex:(int)index shouldHideButton:(BOOL)status ;

@end

@interface EditPopupViewController : UIViewController 

- (IBAction)okButtonPressed:(UIButton *)sender;

- (IBAction)CancelButtonPressed:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIButton *showHideButton;

- (IBAction)showHideButtonPressed:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UITextField *commandTextField;

//define delegate property
@property (nonatomic, assign)id<ButtonConfigureDelegate> delegate;

@property (strong, nonatomic) NSString *command;
@property BOOL isHidden;
@property int iconIndex;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray* iconButtons;

@end
