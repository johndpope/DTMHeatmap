//
//  DMDiffHeatmap.m
//
//  Created by Bryan Oltman on 1/12/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "DMDiffHeatmap.h"
#import "DMDiffColorProvider.h"
#import "DMStandardColorProvider.h"

@interface DMDiffHeatmap ()
@property double maxValue;
@property double zoomedOutMax;
@property NSDictionary *pointsWithHeat;
@property CLLocationCoordinate2D center;
@property MKMapRect boundingRect;
@end

@implementation DMDiffHeatmap

@synthesize maxValue, pointsWithHeat = _pointsWithHeat;
@synthesize zoomedOutMax;
@synthesize center, boundingRect;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.colorProvider = [DMDiffColorProvider new];
    }
    
    return self;
}

- (void)setBeforeData:(NSDictionary *)before
            afterData:(NSDictionary *)after
{
    self.maxValue = 0;
    
    NSMutableDictionary *newHeatMapData = [NSMutableDictionary new];
    for (NSValue *mapPointValue in [before allKeys]) {
        newHeatMapData[mapPointValue] = @(-1 * [before[mapPointValue] doubleValue]);
    }
    
    for (NSValue *mapPointValue in [after allKeys]) {
        if (newHeatMapData[mapPointValue]) {
            double beforeValue = [newHeatMapData[mapPointValue] doubleValue];
            double afterValue = [after[mapPointValue] doubleValue];
            newHeatMapData[mapPointValue] = @(beforeValue + afterValue);
        } else {
            newHeatMapData[mapPointValue] = after[mapPointValue];
        }
    }
    
    MKMapPoint upperLeftPoint, lowerRightPoint;
    [[[newHeatMapData allKeys] lastObject] getValue:&upperLeftPoint];
    lowerRightPoint = upperLeftPoint;
    
    float *buckets = calloc(kSBZoomZeroDimension * kSBZoomZeroDimension, sizeof(float));
    for (NSValue *mapPointValue in newHeatMapData) {
        MKMapPoint point;
        [mapPointValue getValue:&point];
        double value = [[newHeatMapData objectForKey:mapPointValue] doubleValue];
       
        if (point.x < upperLeftPoint.x) upperLeftPoint.x = point.x;
        if (point.y < upperLeftPoint.y) upperLeftPoint.y = point.y;
        if (point.x > lowerRightPoint.x) lowerRightPoint.x = point.x;
        if (point.y > lowerRightPoint.y) lowerRightPoint.y = point.y;
        
        double abs = ABS(value);
        if (abs > self.maxValue) {
            self.maxValue = abs;
        }
        
        //bucket the map point:
        int col = point.x / (kSBMapKitPoints / kSBZoomZeroDimension);
        int row = point.y / (kSBMapKitPoints / kSBZoomZeroDimension);
        
        int offset = kSBZoomZeroDimension * row + col;
        
        buckets[offset] += value;
    }
    
    for (int i = 0; i < kSBZoomZeroDimension * kSBZoomZeroDimension; i++) {
        double abs = ABS(buckets[i]);
        if (abs > self.zoomedOutMax) {
            self.zoomedOutMax = abs;
        }
    }
    
    free(buckets);
    
    double width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding;
    double height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding;
    
    self.boundingRect = MKMapRectMake(upperLeftPoint.x - kSBMapRectPadding / 2,
                                      upperLeftPoint.y - kSBMapRectPadding / 2,
                                      width, height);
    self.center = MKCoordinateForMapPoint(MKMapPointMake(upperLeftPoint.x + width / 2,
                                                         upperLeftPoint.y + height / 2));
    self.pointsWithHeat = newHeatMapData;
}

@end
