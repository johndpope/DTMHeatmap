//
//  DMHeatmap.m
//  HeatMapTest
//
//  Created by Bryan Oltman on 1/6/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMHeatmap.h"

static const CGFloat kSBMapRectPadding = 100000;
static const int kSBZoomZeroDimension = 256;
static const int kSBMapKitPoints = 536870912;
static const int kSBZoomLevels = 20;

// Alterable constant to change look of heat map
static const int kSBScalePower = 4;

// Alterable constant to trade off accuracy with performance
// Increase for big data sets which draw slowly
static const int kSBScreenPointsPerBucket = 10;

@interface DMHeatmap ()
@property (nonatomic) double maxValue;
@property double zoomedOutMax;
@property (nonatomic) NSDictionary *pointsWithHeat;
@property CLLocationCoordinate2D center;
@property MKMapRect boundingRect;
@end

@implementation DMHeatmap

- (id)initWithData:(NSDictionary *)heatMapData
{
    if (self = [super init]) {
        [self setData:heatMapData];
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
    
    // iterate through to find the max and the bounding region
    // set up the internal model with the data
    // TODO: make sure this dictionary has the correct typing
    for (NSValue *mapPointValue in newHeatMapData) {
        MKMapPoint point;
        [mapPointValue getValue:&point];
        
        if (point.x < upperLeftPoint.x) upperLeftPoint.x = point.x;
        if (point.y < upperLeftPoint.y) upperLeftPoint.y = point.y;
        if (point.x > lowerRightPoint.x) lowerRightPoint.x = point.x;
        if (point.y > lowerRightPoint.y) lowerRightPoint.y = point.y;
        
        NSNumber *value = [newHeatMapData objectForKey:mapPointValue];
        
        if ([value doubleValue] > self.maxValue) {
            self.maxValue = [value doubleValue];
        }
        
        //bucket the map point:
        int col = point.x / (kSBMapKitPoints / kSBZoomZeroDimension);
        int row = point.y / (kSBMapKitPoints / kSBZoomZeroDimension);
        
        int offset = kSBZoomZeroDimension * row + col;
        
        buckets[offset] += [value doubleValue];
    }
    
    for (int i = 0; i < kSBZoomZeroDimension * kSBZoomZeroDimension; i++) {
        if (buckets[i] > self.zoomedOutMax) {
            self.zoomedOutMax = buckets[i];
        }
    }
    
    free(buckets);
    
    // make the new bounding region from the two corners
    double width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding;
    double height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding;
    self.boundingRect = MKMapRectMake(upperLeftPoint.x - kSBMapRectPadding / 2,
                                      upperLeftPoint.y - kSBMapRectPadding / 2,
                                      width, height);
    
    MKMapPoint centerPoint = MKMapPointMake(upperLeftPoint.x + width / 2,
                                            upperLeftPoint.y + height / 2);
    self.center = MKCoordinateForMapPoint(centerPoint);
    
    _pointsWithHeat = newHeatMapData;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.center;
}

- (MKMapRect)boundingMapRect
{
    return self.boundingRect;
}

- (NSDictionary *)mapPointsWithHeatInMapRect:(MKMapRect)rect atScale:(MKZoomScale)scale
{
    NSMutableDictionary *toReturn = [[NSMutableDictionary alloc] init];
    int bucketDelta = kSBScreenPointsPerBucket / scale;
    
    double zoomScale = log2(1/scale);
    double slope = (self.zoomedOutMax - self.maxValue) / (kSBZoomLevels - 1);
    double x = pow(zoomScale, kSBScalePower) / pow(kSBZoomLevels, kSBScalePower - 1);
    double scaleFactor = (x - 1) * slope + self.maxValue;
    
    if (scaleFactor < self.maxValue) {
        scaleFactor = self.maxValue;
    }
    
    for (NSValue *key in self.pointsWithHeat) {
        MKMapPoint point;
        [key getValue:&point];
        
        if (!MKMapRectContainsPoint(rect, point)) {
            continue;
        }
        
        // Scale the value down by the max and add it to the return dictionary
        NSNumber *value = [self.pointsWithHeat objectForKey:key];
        double unscaled = [value doubleValue];
        double scaled = unscaled / scaleFactor;
        
        MKMapPoint bucketPoint;
        int originalX = point.x;
        int originalY = point.y;
        bucketPoint.x = originalX - originalX % bucketDelta + bucketDelta / 2;
        bucketPoint.y = originalY - originalY % bucketDelta + bucketDelta / 2;
        NSValue *bucketKey = [NSValue value:&bucketPoint withObjCType:@encode(MKMapPoint)];
        
        NSNumber *existingValue = [toReturn objectForKey:bucketKey];
        if (existingValue) {
            scaled += [existingValue doubleValue];
        }
        
        [toReturn setObject:[NSNumber numberWithDouble:scaled] forKey:bucketKey];
    }
    
    return toReturn;
}

@end
