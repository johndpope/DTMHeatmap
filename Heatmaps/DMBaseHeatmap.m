//
//  DMHeatmap.m
//  HeatMapTest
//
//  Created by Bryan Oltman on 1/6/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMBaseHeatmap.h"

@implementation DMBaseHeatmap

- (CLLocationCoordinate2D)coordinate
{
    return self.center;
}

- (MKMapRect)boundingMapRect
{
    return self.boundingRect;
}

- (NSDictionary *)mapPointsWithHeatInMapRect:(MKMapRect)rect
                                     atScale:(MKZoomScale)scale
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
        
        NSNumber *existingValue = toReturn[bucketKey];
        if (existingValue) {
            scaled += [existingValue doubleValue];
        }
        
        [toReturn setObject:[NSNumber numberWithDouble:scaled] forKey:bucketKey];
    }
    
    return toReturn;
}

@end
