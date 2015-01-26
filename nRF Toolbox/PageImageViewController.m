//
//  PageImageViewController.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 23/01/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "PageImageViewController.h"

@interface PageImageViewController ()

@end

@implementation PageImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.pageImage.image = [UIImage imageNamed:self.pageImageFileName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skipButtonPressed:(UIButton *)sender {
    [self showHelpNavigationBar];
    [self showTabBar];
    [self removePageViewControllersFromHelp];
}

-(void)showHelpNavigationBar
{
    [self.parentViewController.parentViewController.navigationController setNavigationBarHidden:NO];
}

-(void)showTabBar
{
    [self.parentViewController.parentViewController.tabBarController.tabBar setHidden:NO];
}

-(void)removePageViewControllersFromHelp
{
    [self.parentViewController.view removeFromSuperview];
    [self.parentViewController removeFromParentViewController];
}

@end
