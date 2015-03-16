//
//  FolderFilesTableViewController.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 23/07/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "FolderFilesTableViewController.h"
#import "AccessFileSystem.h"

@interface FolderFilesTableViewController ()

@property (nonatomic, strong)AccessFileSystem *fileSystem;

@end

@implementation FolderFilesTableViewController

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
    self.fileSystem = [[AccessFileSystem alloc]init];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (self.files.count == 0) {
        [Utility showAlert:@"There are no Hex or Zip files found inside selected folder."];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.files.count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    return self.files.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FolderFilesCell" forIndexPath:indexPath];
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    // Configure the cell...
    if ([self.fileSystem checkFileExtension:fileName fileExtension:HEX]) {
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    else if ([self.fileSystem checkFileExtension:fileName fileExtension:ZIP]) {
        cell.imageView.image = [UIImage imageNamed:@"zipFile"];
    }

    cell.textLabel.text = [self.files objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *fileName = [self.files objectAtIndex:indexPath.row];
    NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [self.fileDelegate onFileSelected:fileURL];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    NSLog(@"setEditing");
    [self.tableView setEditing:editing animated:YES];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"editingStyleForRowAtIndexPath");
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"commitEditingStyle");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *fileName = [self.files objectAtIndex:indexPath.row];
        NSLog(@"Removing file: %@",fileName);
        [self.files removeObjectAtIndex:indexPath.row];
        NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
        NSLog(@"Removing file from path %@",filePath);
        [self.fileSystem deleteFile:filePath];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];        
    }
}

@end
