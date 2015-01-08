//
//  DMHeatmap.h
//  HeatMapTest
//
//  Created by Bryan Oltman on 1/6/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSInteger, DMHeatmapMode) {
    DMHeatmapModeStandard,  // A standard heatmap with the full color spectrum representing 0..1
    DMHeatmapModeDiff       // A heatmap with cool colors representing -1..0 and warm colors representing 0..1
};

@interface DMHeatmap : NSObject <MKOverlay>

+ (instancetype)heatmapWithMode:(DMHeatmapMode)mode;

- (void)setData:(NSDictionary *)newHeatMapData;
- (NSDictionary *)mapPointsWithHeatInMapRect:(MKMapRect)rect
                                     atScale:(MKZoomScale)scale;
- (MKMapRect)boundingMapRect;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) DMHeatmapMode heatmapMode;

@end
