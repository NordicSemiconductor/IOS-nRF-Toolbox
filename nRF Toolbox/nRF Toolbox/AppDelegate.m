//
//  AppDelegate.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 12/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "AppDelegate.h"
#import "DFUViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    UIImage *navBackgroundImage = [UIImage imageNamed:@"NavBarIOS7"];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
    
    NSDictionary* defaults = [NSDictionary dictionaryWithObjects:@[@"2.3", [NSNumber numberWithInt:10]] forKeys:@[@"key_diameter", @"dfu_number_of_packets"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"URL for open file from Email: %@",url);
    UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
    [navigationController popToRootViewControllerAnimated:NO];
    
    UIStoryboard *main = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    DFUViewController *dfuvc = [main instantiateViewControllerWithIdentifier:@"DFUViewController"];
    [dfuvc onFileSelected:url];
    
    [navigationController pushViewController:dfuvc animated:YES];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
