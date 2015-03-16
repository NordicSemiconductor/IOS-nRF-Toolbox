//
//  HelpViewController.m
//  nRF Toolbox
//
//  Created by Nordic Semiconductor on 06/02/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "HelpViewController.h"
#import "Constants.h"
#import "PageImageViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

@synthesize backgroundImage;
@synthesize helpTextView;
@synthesize helpText;

int PAGE_NUMBERS;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
    helpTextView.text = helpText;

    if (self.isDFUViewController) {
        [self hideNavigationBar];
        [self initDFUDemoImages];
        [self showDFUDemo];
        self.isDFUViewController = NO;
    }
    else if (self.isAppFileTableViewController) {
        [self hideNavigationBar];
        [self initUserFilesDemoImages];
        [self.tabBarController.tabBar setHidden:YES];
        [self showDFUDemo];
        self.isAppFileTableViewController = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) hideNavigationBar
{
    [self.navigationController setNavigationBarHidden:YES];
}

-(void) initDFUDemoImages
{
    self.pageContentImages = @[@"DFU_Main_Page.png",
                               @"Application_Zip_Image.png",
                               @"Bootloader_Zip_Image.png",
                               @"Softdevice_Zip_Image.png",
                               @"System_Zip_Image.png"];
    
    PAGE_NUMBERS = [self.pageContentImages count];
}

-(void) initUserFilesDemoImages
{
    self.pageContentImages = @[@"AddingFiles",
                               @"Itunes1.png",
                               @"Itunes2.png",
                               @"EmailAttachment1.png",
                               @"EmailAttachment2.png"];
    
    PAGE_NUMBERS = [self.pageContentImages count];
}


-(void) showDFUDemo
{
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IdPageViewController"];
    
    //Assign datasource (pages or viewcontrollers) of PageViewController to self
    self.pageViewController.dataSource = self;
    
    //set pages or viewcontrollers of PageViewController
    PageImageViewController *pageContentViewController = [self createPageContentViewControllerAtIndex:0];
    NSArray *pageContentViewControllers = @[pageContentViewController];
    [self.pageViewController setViewControllers:pageContentViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:Nil];
    
    // Change the size of page view controller
    /*self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 100);*/
    
    //Add PageViewController to this Root View Controller as child viewcontroller
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}


-(PageImageViewController *)createPageContentViewControllerAtIndex:(NSUInteger)index
{
    if (index >= PAGE_NUMBERS || PAGE_NUMBERS < 1) {
        return nil;
    }
    PageImageViewController *pageContentVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IdPageImageViewController"];
    pageContentVC.pageIndex = index;
    pageContentVC.pageImageFileName = self.pageContentImages[index];
    return pageContentVC;
}


#pragma mark - Page View Controller Data Source

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSLog(@"pageViewController viewControllerBeforeViewController");
    NSUInteger index = ((PageImageViewController *)viewController).pageIndex;
    if ((index == 0) || (index == NSNotFound)) {
        NSLog(@"page index is equal to first Page Number or index not found");
        return nil;
    }
    NSLog(@"decreasing page index");
    index--;
    return [self createPageContentViewControllerAtIndex:index];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSLog(@"pageViewController viewControllerAfterViewController");
    NSUInteger index = ((PageImageViewController *)viewController).pageIndex;
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    if (index == PAGE_NUMBERS) {
        NSLog(@"page index is equal to Max Page Number");
        return nil;
    }
    NSLog(@"increasing page index");
    return [self createPageContentViewControllerAtIndex:index];
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    NSLog(@"presentationCountForPageViewController %d",PAGE_NUMBERS);
    return PAGE_NUMBERS;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    NSLog(@"presentationIndexForPageViewController");
    return 0;
}

@end
