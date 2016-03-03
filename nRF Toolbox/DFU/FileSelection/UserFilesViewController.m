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
@property (weak, nonatomic) IBOutlet UIView *emptyView;

@end

@implementation UserFilesViewController

@synthesize tableView;
@synthesize emptyView;
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
    [self ensureFolderNotEmpty];
}

-(void)ensureFolderNotEmpty
{
    if (self.files.count == 0)
    {
        emptyView.hidden = NO;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionred
{
    return self.files.count + 1; // at row #1 there is a Tutorial
}

-(CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        return 84; // Tutorial row
    }
    else
    {
        return 44; // Normal row
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        // Tutorial row
        return [tv dequeueReusableCellWithIdentifier:@"UserFilesCellHelp" forIndexPath:indexPath];
    }
    
    // Normal row
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"UserFilesCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileName = [self.files objectAtIndex:indexPath.row - 1];
    NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
    
    cell.textLabel.text = fileName;
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
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:@"hex"])
    {
        cell.imageView.image = [UIImage imageNamed:@"ic_file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:@"bin"])
    {
        cell.imageView.image = [UIImage imageNamed:@"ic_file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:@"zip"])
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
    if (indexPath.row == 0)
    {
        // Tutorial row
        [self performSegueWithIdentifier:@"OpenTutorial" sender:self];
    }
    else
    {
        // Normal row
        NSString *fileName = [self.files objectAtIndex:indexPath.row - 1];
        NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
        
        if (![self.fileSystem isDirectory:filePath])
        {
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            [self onFilePreselected:fileURL];
        }
        else
        {
            // Folder clicked
            [self performSegueWithIdentifier:@"OpenFolder" sender:self];
        }
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        // Inbox folder can't be deleted
        NSString *fileName = [self.files objectAtIndex:indexPath.row - 1];
        if (![fileName isEqualToString:@"Inbox"])
        {
            return UITableViewCellEditingStyleDelete;
        }
    }
    return UITableViewCellEditingStyleNone;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *fileName = [self.files objectAtIndex:indexPath.row - 1];
        NSString *filePath = [self.documentsDirectoryPath stringByAppendingPathComponent:fileName];
        [self.fileSystem deleteFile:filePath];
        [self.files removeObjectAtIndex:indexPath.row - 1];
        [tv deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if ([filePath isEqualToString:selectedPath])
        {
            [self onFilePreselected:nil];
        }
        
        [self performSelector:@selector(ensureFolderNotEmpty) withObject:nil afterDelay:0.6];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenFolder"])
    {
        NSIndexPath *selectionIndexPath = [self.tableView indexPathForSelectedRow];
        NSString *fileName = [self.files objectAtIndex:selectionIndexPath.row - 1];
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
}

@end
