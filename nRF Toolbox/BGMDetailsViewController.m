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

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *sequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *concentration;
@property (weak, nonatomic) IBOutlet UILabel *lowBatteryStatus;
@property (weak, nonatomic) IBOutlet UILabel *sensorMalfunctionStatus;
@property (weak, nonatomic) IBOutlet UILabel *insufficienSampleStatus;
@property (weak, nonatomic) IBOutlet UILabel *stripInsertionStatus;
@property (weak, nonatomic) IBOutlet UILabel *stripTypeStatus;
@property (weak, nonatomic) IBOutlet UILabel *resultTooHighStatus;
@property (weak, nonatomic) IBOutlet UILabel *resultTooLowStatus;
@property (weak, nonatomic) IBOutlet UILabel *tempTooHighStatus;
@property (weak, nonatomic) IBOutlet UILabel *tempTooLowStatus;
@property (weak, nonatomic) IBOutlet UILabel *stripPulledTooSoonStatus;
@property (weak, nonatomic) IBOutlet UILabel *deviceFaultStatus;
@property (weak, nonatomic) IBOutlet UILabel *timeStatus;
@property (weak, nonatomic) IBOutlet UILabel *contextPresentStatus;
@property (weak, nonatomic) IBOutlet UILabel *carbodydrateId;
@property (weak, nonatomic) IBOutlet UILabel *carbohydrate;
@property (weak, nonatomic) IBOutlet UILabel *meal;
@property (weak, nonatomic) IBOutlet UILabel *tester;
@property (weak, nonatomic) IBOutlet UILabel *health;
@property (weak, nonatomic) IBOutlet UILabel *exerciseDuration;
@property (weak, nonatomic) IBOutlet UILabel *exerciseIntensity;
@property (weak, nonatomic) IBOutlet UILabel *medication;
@property (weak, nonatomic) IBOutlet UILabel *medicationUnit;
@property (weak, nonatomic) IBOutlet UILabel *medicationId;
@property (weak, nonatomic) IBOutlet UILabel *HbA1c;

- (void) updateView:(UILabel*)label withStatus:(BOOL)status;

@end

@implementation BGMDetailsViewController
@synthesize reading;
@synthesize scrollView;
@synthesize backgroundImage;
@synthesize sequenceNumber;
@synthesize timestamp;


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
    timestamp.text = [dateFormat stringFromDate:reading.timestamp];
    if (reading.glucoseConcentrationTypeAndLocationPresent)
    {
        self.type.text = [reading typeAsString];
        self.location.text = [reading locationAsString];
        self.concentration.text = [NSString stringWithFormat:@"%.1f", reading.glucoseConcentration];
    }
    else
    {
        self.type.text = @"Unavailable";
        self.location.text = @"Unavailable";
        self.concentration.text = @"-";
    }
    
    //reading.sensorStatusAnnunciationPresent = YES;
    //reading.sensorStatusAnnunciation = 0x73C3;
    if (reading.sensorStatusAnnunciationPresent)
    {
        UInt16 status = reading.sensorStatusAnnunciation;
        [self updateView:self.lowBatteryStatus withStatus:(status & 0x0001) > 0];
        [self updateView:self.sensorMalfunctionStatus withStatus:(status & 0x0002) > 0];
        [self updateView:self.insufficienSampleStatus withStatus:(status & 0x0004) > 0];
        [self updateView:self.stripInsertionStatus withStatus:(status & 0x0008) > 0];
        [self updateView:self.stripTypeStatus withStatus:(status & 0x0010) > 0];
        [self updateView:self.resultTooHighStatus withStatus:(status & 0x0020) > 0];
        [self updateView:self.resultTooLowStatus withStatus:(status & 0x0040) > 0];
        [self updateView:self.tempTooHighStatus withStatus:(status & 0x0080) > 0];
        [self updateView:self.tempTooLowStatus withStatus:(status & 0x0100) > 0];
        [self updateView:self.stripPulledTooSoonStatus withStatus:(status & 0x0200) > 0];
        [self updateView:self.deviceFaultStatus withStatus:(status & 0x0400) > 0];
        [self updateView:self.timeStatus withStatus:(status & 0x0800) > 0];
    }
    
    if (reading.context != nil)
    {
        GlucoseReadingContext* context = reading.context;
        self.contextPresentStatus.text = @"Available";
        
        if (context.carbohydratePresent)
        {
            self.carbodydrateId.text = [context carbohydrateIdAsString];
            self.carbohydrate.text = [NSString stringWithFormat:@"%.1f", context.carbohydrate * 1000];
        }
        
        if (context.mealPresent)
        {
            self.meal.text = [context mealIdAsString];
        }
        
        if (context.testerAndHealthPresent)
        {
            self.tester.text = [context testerAsString];
            self.health.text = [context healthAsString];
        }
        
        if (context.exercisePresent)
        {
            self.exerciseDuration.text = [NSString stringWithFormat:@"%d", context.exerciseDuration / 60];
            self.exerciseIntensity.text = [NSString stringWithFormat:@"%d", context.exerciseIntensity];
        }
        
        if (context.medicationPresent)
        {
            self.medicationId.text = [context medicationIdAsString];
            self.medication.text = [NSString stringWithFormat:@"%.0f", context.medication * 1000];
            if (context.medicationUnit == KILOGRAMS)
            {
                self.medicationUnit.text = @"mg";
            }
            else
            {
                self.medicationUnit.text = @"ml";
            }
        }
        
        if (context.HbA1cPresent)
        {
            self.HbA1c.text = [NSString stringWithFormat:@"%.2f", context.HbA1c];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateView:(UILabel *)label withStatus:(BOOL)status
{
    if (status)
    {
        label.text = @"YES";
        label.textColor = [UIColor redColor];
    }
    else
    {
        label.text = @"NO";
    }
}

@end
