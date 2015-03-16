//
//  FileTypeTableViewController.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 18/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "FileTypeTableViewController.h"
#import "Utility.h"

@interface FileTypeTableViewController ()

@end

@implementation FileTypeTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView setBackgroundView:[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background4"]]];
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
    return [[Utility getFirmwareTypes]count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileTypeCell" forIndexPath:indexPath];
    
    if ([[[Utility getFirmwareTypes] objectAtIndex:indexPath.row] isEqual:self.chosenFirmwareType]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.textLabel.text = [[Utility getFirmwareTypes] objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * selectionIndexPath = [self.tableView indexPathForSelectedRow];
    NSString *firmwareType = [[Utility getFirmwareTypes] objectAtIndex:selectionIndexPath.row];
    self.chosenFirmwareType = firmwareType;
}


@end
