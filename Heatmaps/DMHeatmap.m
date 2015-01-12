//
//  DMHeatmap.m
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/12/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMHeatmap.h"
#import "DMStandardColorProvider.h"

@interface DMHeatmap ()
@property double maxValue;
@property double zoomedOutMax;
@property NSDictionary *pointsWithHeat;
@property CLLocationCoordinate2D center;
@property MKMapRect boundingRect;
@end

@implementation DMHeatmap

@synthesize maxValue, pointsWithHeat = _pointsWithHeat;
@synthesize zoomedOutMax;
@synthesize center, boundingRect;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.colorProvider = [DMStandardColorProvider new];
    }
    
    return self;
}

- (void)setData:(NSDictionary *)newHeatMapData
{
    if (newHeatMapData == _pointsWithHeat) {
        return;
    }
    
    self.maxValue = 0;
    
    MKMapPoint upperLeftPoint, lowerRightPoint;
    [[[newHeatMapData allKeys] lastObject] getValue:&upperLeftPoint];
    lowerRightPoint = upperLeftPoint;
    
    float *buckets = calloc(kSBZoomZeroDimension * kSBZoomZeroDimension, sizeof(float));
    for (NSValue *mapPointValue in newHeatMapData) {
        MKMapPoint point;
        [mapPointValue getValue:&point];
        
        if (point.x < upperLeftPoint.x) upperLeftPoint.x = point.x;
        if (point.y < upperLeftPoint.y) upperLeftPoint.y = point.y;
        if (point.x > lowerRightPoint.x) lowerRightPoint.x = point.x;
        if (point.y > lowerRightPoint.y) lowerRightPoint.y = point.y;
        
        double value = [[newHeatMapData objectForKey:mapPointValue] doubleValue];
        
        if (value > self.maxValue) {
            self.maxValue = value;
        }
        
        //bucket the map point:
        int col = point.x / (kSBMapKitPoints / kSBZoomZeroDimension);
        int row = point.y / (kSBMapKitPoints / kSBZoomZeroDimension);
        
        int offset = kSBZoomZeroDimension * row + col;
        
        buckets[offset] += value;
    }
    
    for (int i = 0; i < kSBZoomZeroDimension * kSBZoomZeroDimension; i++) {
        if (buckets[i] > self.zoomedOutMax) {
            self.zoomedOutMax = buckets[i];
        }
    }
    
    free(buckets);
    
    //make the new bounding region from the two corners
    //probably should do some cusioning
    double width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding;
    double height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding;
    
    self.boundingRect = MKMapRectMake(upperLeftPoint.x - kSBMapRectPadding / 2, upperLeftPoint.y - kSBMapRectPadding / 2, width, height);
    self.center = MKCoordinateForMapPoint(MKMapPointMake(upperLeftPoint.x + width / 2, upperLeftPoint.y + height / 2));
    
    _pointsWithHeat = newHeatMapData;
}

@end
