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
    [super viewDidLoad];
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
    
    PAGE_NUMBERS = (int)[self.pageContentImages count];
}

-(void) initUserFilesDemoImages
{
    self.pageContentImages = @[@"AddingFiles",
                               @"Itunes1.png",
                               @"Itunes2.png",
                               @"EmailAttachment1.png",
                               @"EmailAttachment2.png"];
    
    PAGE_NUMBERS = (int)[self.pageContentImages count];
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
