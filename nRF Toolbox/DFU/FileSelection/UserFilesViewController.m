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

#import "UserFilesViewController.h"
#import "AccessFileSystem.h"
#import "Utility.h"
#import "AppFilesViewController.h"
#import "FolderFilesViewController.h"


@interface UserFilesViewController ()

@property (nonatomic,strong)NSMutableArray *files;
@property (nonatomic,strong)NSString *documentsDirectoryPath;
@property (nonatomic,strong)AccessFileSystem *fileSystem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation UserFilesViewController

@synthesize tableView;
@synthesize selectedPath;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fileSystem = [[AccessFileSystem alloc] init];
    self.documentsDirectoryPath = [self.fileSystem getDocumentsDirectoryPath];
    self.files = [[self.fileSystem getDirectoriesAndRequiredFilesFromDocumentsDirectory] mutableCopy];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = selectedPath != nil;
    [tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionred
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"UserFilesCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([self.fileSystem isDirectory:filePath])
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([fileName isEqualToString:@"Inbox"])
        {
            cell.imageView.image = [UIImage imageNamed:@"ic_email"];
        }
        else
        {
            cell.imageView.image = [UIImage imageNamed:@"ic_folder"];
        }
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:HEX])
    {
        cell.imageView.image = [UIImage imageNamed:@"ic_file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:BIN])
    {
        cell.imageView.image = [UIImage imageNamed:@"ic_file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:ZIP])
    {
        cell.imageView.image = [UIImage imageNamed:@"ic_archive"];
    }
    
    if ([filePath isEqualToString:selectedPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

-(void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    if (![self.fileSystem isDirectory:filePath]) {
        selectedPath = filePath;
        [tv reloadData];
        self.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
        
        AppFilesViewController* appFilesVC = self.tabBarController.viewControllers.firstObject;
        appFilesVC.selectedPath = selectedPath;
    }
}

-(void)onFilePreselected:(NSURL *)fileURL
{
    selectedPath = [fileURL path];
    [tableView reloadData];
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = fileURL != nil;
    
    AppFilesViewController* appFilesVC = self.tabBarController.viewControllers.firstObject;
    appFilesVC.selectedPath = selectedPath;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *fileName = [self.files objectAtIndex:indexPath.row];
        
        if (![fileName isEqualToString:@"Inbox"])
        {
            NSLog(@"Removing file: %@",fileName);
            [self.files removeObjectAtIndex:indexPath.row];
            NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
            NSLog(@"Removing file from path %@",filePath);
            [self.fileSystem deleteFile:filePath];
            [tv deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            if ([filePath isEqualToString:selectedPath])
            {
                selectedPath = nil;
                [tableView reloadData];
                
                AppFilesViewController* appFilesVC = self.tabBarController.viewControllers.firstObject;
                appFilesVC.selectedPath = nil;
                self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
            }
        }
        else
        {
            NSLog(@"Can't remove Inbox directory");
            [Utility showAlert:@"User can't delete Inbox directory"];
            [tv reloadData];
        }
    }
}

#pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSIndexPath *selectionIndexPath = [self.tableView indexPathForSelectedRow];
    NSString *fileName = [self.files objectAtIndex:selectionIndexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    return [self.fileSystem isDirectory:filePath];
}
 
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *selectionIndexPath = [self.tableView indexPathForSelectedRow];
    NSString *fileName = [self.files objectAtIndex:selectionIndexPath.row];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    if ([self.fileSystem isDirectory:filePath])
    {
        FolderFilesViewController *folderVC = [segue destinationViewController];
        folderVC.directoryPath = filePath;
        folderVC.directoryName = fileName;
        folderVC.files = [[self.fileSystem getRequiredFilesFromDirectory:filePath] mutableCopy];
        folderVC.fileDelegate = self.fileDelegate;
        folderVC.preselectionDelegate = self;
        folderVC.selectedPath = selectedPath;
    }
}

@end
