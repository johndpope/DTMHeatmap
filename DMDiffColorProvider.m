//
//  DMDiffColorProvider.m
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMDiffColorProvider.h"

@implementation DMDiffColorProvider

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    static int maxVal = 255;
    double absValue;
    
    if (value == 0) {
        return;
    }
    
    if (value < 0) {
        // Cool color to represent a decrease
        absValue = sqrt(MIN(-value, 1));
        
        *blue = absValue * maxVal;
        *alpha = *blue;
        if (absValue >= 0.75) {
            *green = *blue;
        } else if (absValue >= 0.5) {
            *green = (absValue - 0.5) * maxVal * 3;
        }
        
        if (absValue >= 0.8) {
            *red = (absValue - 0.8) * maxVal * 5;
        }
    } else {
        // Warm color to represent an increase
        absValue = sqrt(MIN(value, 1));
        
        *red = absValue * maxVal;
        *alpha = *red;
        if (absValue >= 0.75) {
            *green = *red;
        } else if (absValue >= 0.5) {
            *green = (absValue - 0.5) * maxVal * 3;
        }
        
        if (absValue >= 0.8) {
            *blue = (absValue - 0.8) * maxVal * 5;
        }
    }
}

@end
