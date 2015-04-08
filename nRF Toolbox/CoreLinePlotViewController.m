//
//  CoreLinePlotViewController.m
//  nRF Toolbox
//
//  Created by Kamran Saleem Soomro on 26/03/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "CoreLinePlotViewController.h"

@interface CoreLinePlotViewController ()

@end

@implementation CoreLinePlotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark HRM Graph methods

-(void)initLinePlot
{
    //Initialize and display Graph (x and y axis lines)
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphView.bounds];
    self.hostView = [[CPTGraphHostingView alloc] initWithFrame:self.graphView.bounds];
    self.hostView.hostedGraph = self.graph;
    [self.graphView addSubview:hostView];
    
    //apply styling to Graph
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph.backgroundColor = nil;
    self.graph.fill = nil;
    self.graph.plotAreaFrame.fill = nil;
    self.graph.plotAreaFrame.plotArea.fill = nil;
    
    //This removes top and right lines of graph
    self.graph.plotAreaFrame.borderLineStyle = nil;
    //This shows x and y axis labels from 0 to 1
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    // set padding for graph from Left and Bottom
    self.graph.paddingBottom = 30;
    self.graph.paddingLeft = 50;
    self.graph.paddingRight = 0;
    self.graph.paddingTop = 0;
    
    //Define x and y axis range
    // x-axis from 0 to 100
    // y-axis from 0 to 300
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotXMinRange)
                                                    length:CPTDecimalFromInt(plotXMaxRange)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    NSNumberFormatter *axisLabelFormatter = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(plotXInterval);
    axisSet.xAxis.minorTicksPerInterval = 4;
    axisSet.xAxis.minorTickLength = 5;
    axisSet.xAxis.majorTickLength = 7;
    axisSet.xAxis.title = @"Time(Seconds)";
    axisSet.xAxis.titleOffset = 25;
    axisSet.xAxis.labelFormatter = axisLabelFormatter;
    
    //Define y-axis properties
    //y-axis intermediate interval = 50;
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromInt(plotYInterval);
    axisSet.yAxis.minorTicksPerInterval = 4;
    axisSet.yAxis.minorTickLength = 5;
    axisSet.yAxis.majorTickLength = 7;
    axisSet.yAxis.title = @"BPM";
    axisSet.yAxis.titleOffset = 30;
    axisSet.yAxis.labelFormatter = axisLabelFormatter;
    
    
    //Define line plot and set line properties
    self.linePlot = [[CPTScatterPlot alloc] init];
    self.linePlot.dataSource = self;
    [self.graph addPlot:self.linePlot toPlotSpace:plotSpace];
    
    //set line plot style
    CPTMutableLineStyle *lineStyle = [self.linePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth = 2;
    lineStyle.lineColor = [CPTColor blackColor];
    self.linePlot.dataLineStyle = lineStyle;
    
    CPTMutableLineStyle *symbolineStyle = [CPTMutableLineStyle lineStyle];
    symbolineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
    symbol.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
    symbol.lineStyle = symbolineStyle;
    symbol.size = CGSizeMake(3.0f, 3.0f);
    self.linePlot.plotSymbol = symbol;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle = [[CPTMutableLineStyle alloc] init];
    gridLineStyle.lineColor = [CPTColor grayColor];
    gridLineStyle.lineWidth = 0.5;
    axisSet.xAxis.majorGridLineStyle = gridLineStyle;
    axisSet.yAxis.majorGridLineStyle = gridLineStyle;
    
    
}

-(void)updatePlotSpace
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:@[self.linePlot]];
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotXMinRange)
                                                    length:CPTDecimalFromInt(plotXMaxRange)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(plotXInterval);
}

-(void)addHRValueToGraph:(int)data
{
    [hrValues addObject:[NSDecimalNumber numberWithInt:data]];
    if ([hrValues count] > plotXMaxRange) {
        plotXMaxRange = plotXMaxRange + plotXMaxRange;
        plotXInterval = plotXInterval + plotXInterval;
        [self updatePlotSpace];
    }
    [self.graph reloadData];
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [hrValues count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedInteger:index];
            break;
            
        case CPTScatterPlotFieldY:
            return [hrValues objectAtIndex:index];
            break;
    }
    return [NSDecimalNumber zero];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
