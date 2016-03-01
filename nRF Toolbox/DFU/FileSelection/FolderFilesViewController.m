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

#import "FolderFilesViewController.h"
#include "UserFilesViewController.h"
#import "AccessFileSystem.h"
#import "DFUViewController.h"

@interface FolderFilesViewController ()

@property (nonatomic, strong)AccessFileSystem *fileSystem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *emptyView;

- (IBAction)didClickDone:(id)sender;

@end

@implementation FolderFilesViewController

@synthesize tableView;
@synthesize emptyView;
@synthesize selectedPath;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fileSystem = [[AccessFileSystem alloc] init];
    self.navigationItem.title = self.directoryName;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.rightBarButtonItem.enabled = selectedPath != nil;
    [self ensureFolderNotEmpty];
}

- (IBAction)didClickDone:(id)sender {
    NSURL *fileURL = [NSURL fileURLWithPath:selectedPath];
    [self.fileDelegate onFileSelected:fileURL];
    
    // Go back to DFUViewController
    [self dismissViewControllerAnimated:YES completion:^{
        [self.fileDelegate onFileSelected:fileURL];
    }];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)ensureFolderNotEmpty
{
    if (self.files.count == 0)
    {
        emptyView.hidden = NO;
    }
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

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"FolderFilesCell" forIndexPath:indexPath];
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
    
    // Configure the cell...
    cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    if ([self.fileSystem checkFileExtension:fileName fileExtension:@"hex"])
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
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    selectedPath = filePath;
    [tv reloadData];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [self.preselectionDelegate onFilePreselected:fileURL];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *fileName = [self.files objectAtIndex:indexPath.row];
        NSLog(@"Removing file: %@",fileName);
        
        NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
        [self.fileSystem deleteFile:filePath];
        [self.files removeObjectAtIndex:indexPath.row];
        [tv deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if ([filePath isEqualToString:selectedPath])
        {
            selectedPath = nil;
            
            [self.preselectionDelegate onFilePreselected:nil];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        
        [self performSelector:@selector(ensureFolderNotEmpty) withObject:nil afterDelay:0.6];
    }
}
@end
