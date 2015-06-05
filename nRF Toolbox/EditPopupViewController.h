//
//  EditPopupViewController.h
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 28/05/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

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
