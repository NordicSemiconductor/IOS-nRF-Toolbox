//
//  AppFilesTableViewController.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 21/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "AppFilesTableViewController.h"
#import "AccessFileSystem.h"
#import "UserFilesTableViewController.h"
#import "HelpViewController.h"

@interface AppFilesTableViewController ()

@property (nonatomic,strong)NSArray *files;
@property (nonatomic,strong)NSString *appDirectoryPath;
@property (nonatomic, strong)AccessFileSystem *fileSystem;

@end

@implementation AppFilesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setBackgroundView:[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background4"]]];
    
    self.tabBarController.delegate = self;
    self.fileSystem = [[AccessFileSystem alloc]init];
    self.appDirectoryPath = [self.fileSystem getAppDirectoryPath:@"firmwares"];
    self.files = [self.fileSystem getFilesFromAppDirectory:@"firmwares"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- TabBarController delegate

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSLog(@"UserFilesVC didSelectViewController");
    UINavigationController *navController = [tabBarController.viewControllers objectAtIndex:1];
    UserFilesTableViewController *userFilesVC = (UserFilesTableViewController *)[navController topViewController];
    userFilesVC.fileDelegate = self.fileDelegate;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppFilesCell" forIndexPath:indexPath];
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    
    // Configure the cell...
    cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    if ([self.fileSystem checkFileExtension:fileName fileExtension:HEX]) {
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:ZIP])
    cell.imageView.image = [UIImage imageNamed:@"zipFile"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.appDirectoryPath stringByAppendingPathComponent:fileName];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    [self.fileDelegate onFileSelected:fileURL];
}

- (IBAction)CancelBarButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
     if ([[segue identifier] isEqualToString:@"help"]) {
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [Utility getDFUAppFileHelpText];
    }
    
}


@end
