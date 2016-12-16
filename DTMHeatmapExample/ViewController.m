//
//  ViewController.m
//  DTMHeatMapExample
//
//  Created by Bryan Oltman on 1/7/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "ViewController.h"
#import "DTMHeatmapRenderer.h"
#import "DTMDiffHeatmap.h"
#import "GridTileOverlay.h"
#import "GridTileOverlayRenderer.h"
#import "GeoHash.h"
#import "GeoHelper.h"


@interface ViewController ()
@property (strong, nonatomic) DTMHeatmap *heatmap;
@property (strong, nonatomic) GridTileOverlay *gridTileOverlay;
@property (strong, nonatomic) DTMDiffHeatmap *diffHeatmap;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupHeatmaps];
}




- (void)setupHeatmaps
{
    // Set map region
    MKCoordinateSpan span = MKCoordinateSpanMake(1.0, 1.0);
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(38.5556, -121.4689);
    self.mapView.region = MKCoordinateRegionMake(center, span);

    self.heatmap = [DTMHeatmap new];
    self.gridTileOverlay = [[GridTileOverlay alloc] init];
    [self.mapView addOverlay:self.gridTileOverlay];
    

    
    self.heatmap.geoHashPointsWithHeat = [self parseLatLonFileToGeohash:@"mcdonalds"];
    
    [self.heatmap setData:[self parseLatLonFile:@"mcdonalds"]];
    //[self.mapView addOverlay:self.heatmap];

    self.diffHeatmap = [DTMDiffHeatmap new];
    [self.diffHeatmap setBeforeData:[self parseLatLonFile:@"first_week"]
                          afterData:[self parseLatLonFile:@"third_week"]];
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


- (NSDictionary *)parseLatLonFileToGeohash:(NSString *)fileName
{
    NSMutableDictionary *hashes = [NSMutableDictionary new];
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
        NSString *hash = [GeoHash hashForLatitude:latitude longitude:longitude length:2];
        NSString *oneLetter = [hash substringWithRange:NSMakeRange(0, 1)];
        
        NSMutableDictionary *d0 = [hashes valueForKey:hash];
        NSMutableDictionary *d1 = [hashes valueForKey:oneLetter];
        
        if(d0==nil){
            d0 = [NSMutableDictionary dictionary];
        }
        if(d1==nil){
            d1 = [NSMutableDictionary dictionary];
        }
        d0[pointValue] = @(weight);
        d1[pointValue] = @(weight);
        [hashes setValue:d0 forKey:hash];
        [hashes setValue:d1 forKey:oneLetter];
        
    }
    
    return hashes;
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self.mapView removeOverlay:self.diffHeatmap];
            [self.heatmap setData:[self parseLatLonFile:@"mcdonalds"]];
            [self.mapView addOverlay:self.heatmap];
            break;
        case 1:
            [self.mapView removeOverlay:self.diffHeatmap];
            [self.heatmap setData:[self parseLatLonFile:@"first_week"]];
            [self.mapView addOverlay:self.heatmap];
            break;
        case 2:
            [self.mapView removeOverlay:self.diffHeatmap];
            [self.heatmap setData:[self parseLatLonFile:@"third_week"]];
            [self.mapView addOverlay:self.heatmap];
            break;
        case 3:
            [self.mapView removeOverlay:self.heatmap];
            [self.mapView addOverlay:self.diffHeatmap];
            break;
    }
}

#pragma mark - MKMapViewDelegate
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[GridTileOverlay class]]){
        GridTileOverlayRenderer *render = [[GridTileOverlayRenderer alloc] initWithOverlay:self.gridTileOverlay];
        self.gridTileOverlay.weakRenderer = render; //todo decouple scalematrix
        self.gridTileOverlay.weakHeatmap = self.heatmap;
   
        return render;
        
    }
    return [[DTMHeatmapRenderer alloc] initWithOverlay:overlay];
}

@end
