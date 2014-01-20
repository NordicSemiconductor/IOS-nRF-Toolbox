//
//  BGMDetailsViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "BGMDetailsViewController.h"
#import "Constants.h"

@interface BGMDetailsViewController () {
    NSDateFormatter *dateFormat;
}

@property (weak, nonatomic) IBOutlet UILabel *sequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *concentration;

@end

@implementation BGMDetailsViewController
@synthesize reading;
@synthesize backgroundImage;
@synthesize sequenceNumber;
@synthesize timestamp;
@synthesize type;
@synthesize location;
@synthesize concentration;


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd.MM.yyyy, hh:mm:ss"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
    
    sequenceNumber.text = [NSString stringWithFormat:@"%d", reading.sequenceNumber];
    type.text = [reading typeAsString];
    location.text = [reading locationAsString];
    concentration.text = [NSString stringWithFormat:@"%.1f", reading.glucoseConcentration];
    timestamp.text = [dateFormat stringFromDate:reading.timestamp];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
