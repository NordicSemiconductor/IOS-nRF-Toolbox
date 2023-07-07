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

#import "CBGMDetailsViewController.h"
#import "Constants.h"

@interface CBGMDetailsViewController () {
    NSDateFormatter *dateFormat;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *sequenceNumber;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *concentration;
@property (weak, nonatomic) IBOutlet UILabel *unit;
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

@implementation CBGMDetailsViewController
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    sequenceNumber.text = [NSString stringWithFormat:@"%d", reading.sequenceNumber];
    timestamp.text = [dateFormat stringFromDate:reading.timesStamp];
    self.type.text = [reading typeAsString];
    self.location.text = [reading locationAsString];
    self.concentration.text = [NSString stringWithFormat:@"%.1f", reading.glucoseConcentration];
    self.unit.text = @"mg/dL";

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
    
//    if (reading.context != nil)
//    {
//        GlucoseReadingContext* context = reading.context;
//        self.contextPresentStatus.text = @"Available";
//        
//        if (context.carbohydratePresent)
//        {
//            self.carbodydrateId.text = [context carbohydrateIdAsString];
//            self.carbohydrate.text = [NSString stringWithFormat:@"%.1f", context.carbohydrate * 1000];
//        }
//        
//        if (context.mealPresent)
//        {
//            self.meal.text = [context mealIdAsString];
//        }
//        
//        if (context.testerAndHealthPresent)
//        {
//            self.tester.text = [context testerAsString];
//            self.health.text = [context healthAsString];
//        }
//        
//        if (context.exercisePresent)
//        {
//            self.exerciseDuration.text = [NSString stringWithFormat:@"%d", context.exerciseDuration / 60];
//            self.exerciseIntensity.text = [NSString stringWithFormat:@"%d", context.exerciseIntensity];
//        }
//        
//        if (context.medicationPresent)
//        {
//            self.medicationId.text = [context medicationIdAsString];
//            self.medication.text = [NSString stringWithFormat:@"%.0f", context.medication * 1000];
//            if (context.medicationUnit == KILOGRAMS)
//            {
//                self.medicationUnit.text = @"mg";
//            }
//            else
//            {
//                self.medicationUnit.text = @"ml";
//            }
//        }
//        
//        if (context.HbA1cPresent)
//        {
//            self.HbA1c.text = [NSString stringWithFormat:@"%.2f", context.HbA1c];
//        }
//    }
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
