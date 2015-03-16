//
//  ViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 12/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#import "HelpViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize backgroundImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Adjust the background to fill the phone space
    if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue");
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"correct segue");
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"        nRF Toolbox Version %@\n\n The nRF Toolbox application works with a wide range of the most popular Bluetooth Low Energy accessories.",version];
    }
}

@end
