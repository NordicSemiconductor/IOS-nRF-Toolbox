//
//  SelectorViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 14/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "SelectorViewController.h"
#import "ImageCell.h"
#import "AccessFileSystem.h"

@interface SelectorViewController ()
@property (nonatomic,strong)NSArray *images;
@property (nonatomic,strong)NSString *appDirectoryPath;

@end

@implementation SelectorViewController
@synthesize gridView;
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    /*NSError *e;
    NSData *jsonData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"binary_list" withExtension:@"json"]];
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&e];
    self.images = [d objectForKey:@"binaries"];*/
    AccessFileSystem *fileSystem = [[AccessFileSystem alloc]init];
    self.appDirectoryPath = [fileSystem getAppDirectoryPath:@"firmwares"];
    self.images = [fileSystem getFilesFromAppDirectory:@"firmwares"];
    
    gridView.delegate = self;
    gridView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didCancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Collection View Data Source delegate methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    //NSDictionary *image = [self.images objectAtIndex:indexPath.row];
    //cell.title.text = [image objectForKey:@"title"];
    NSString *fileName = [self.images objectAtIndex:indexPath.row];
    cell.title.text = fileName;
    
    return cell;
}

#pragma mark Collection View delegate methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Call delegate method
    /*NSDictionary *image = [self.images objectAtIndex:indexPath.row];
    NSURL *firmwareURL = [[NSBundle mainBundle] URLForResource:[image objectForKey:@"filename"] withExtension:[image objectForKey:@"extension"]];*/
    NSString *fileName = [self.images objectAtIndex:indexPath.row];
    NSString *filePath = [self.appDirectoryPath stringByAppendingPathComponent:fileName];
    
    NSURL *firmwareURL = [NSURL fileURLWithPath:filePath];
    [self.delegate fileSelected:firmwareURL];
}

@end
