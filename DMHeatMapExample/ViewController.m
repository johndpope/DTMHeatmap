//
//  ViewController.m
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/7/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "ViewController.h"
#import "DMHeatmapRenderer.h"
#import "DMDiffHeatmap.h"

@interface ViewController ()
@property (strong, nonatomic) DMHeatmap *heatmap;
@property (strong, nonatomic) DMDiffHeatmap *diffHeatmap;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupStandardHeatmap];
}

- (void)setupStandardHeatmap
{
    // Set map region
    MKCoordinateSpan span = MKCoordinateSpanMake(3.0, 3.0);
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(40.4, -74.4);
    
    self.heatmap = [DMHeatmap new];
    [self.heatmap setData:[self parseLatLonFile:@"mcdonalds"]];
    [self.mapView addOverlay:self.heatmap];
    
    span = MKCoordinateSpanMake(1.0, 1.0);
    center = CLLocationCoordinate2DMake(38.5556, -121.4689);
    self.mapView.region = MKCoordinateRegionMake(center, span);
    self.diffHeatmap = [DMDiffHeatmap new];
    [self.diffHeatmap setBeforeData:[self parseLatLonFile:@"first_week"]
                          afterData:[self parseLatLonFile:@"third_week"]];
//    [self.mapView addOverlay:self.diffHeatmap];
}

- (NSDictionary *)parseLatLonFile:(NSString *)fileName
{
    NSMutableDictionary *ret = [NSMutableDictionary new];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName
                                                     ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByString:@","];
        NSString *latStr = parts[0];
        NSString *lonStr = parts[1];
        
        CLLocationDegrees latitude = [latStr doubleValue];
        CLLocationDegrees longitude = [lonStr doubleValue];
        
        // For this example, each location is weighted equally
        double weight = 1;
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude
                                                          longitude:longitude];
        MKMapPoint point = MKMapPointForCoordinate(location.coordinate);
        NSValue *pointValue = [NSValue value:&point
                                withObjCType:@encode(MKMapPoint)];
        ret[pointValue] = @(weight);
    }
    
    return ret;
}

#pragma mark - MKMapViewDelegate
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    return [[DMHeatmapRenderer alloc] initWithOverlay:overlay];
}

@end
