//
//  ColorProvider.h
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMHeatmap.h"

@interface DMColorProvider : NSObject

+ (DMColorProvider *)providerForMode:(DMHeatmapMode)heatmapMode;

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha;
@end
