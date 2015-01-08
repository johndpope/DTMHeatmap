//
//  ColorProvider.m
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMColorProvider.h"
#import "DMStandardColorProvider.h"
#import "DMDiffColorProvider.h"

@implementation DMColorProvider

+ (DMColorProvider *)providerForMode:(DMHeatmapMode)heatmapMode
{
    static DMStandardColorProvider *standardProvider = nil;
    static DMDiffColorProvider *diffProvider = nil;
    
    switch (heatmapMode) {
        case DMHeatmapModeStandard:
            if (!standardProvider) {
                standardProvider = [DMStandardColorProvider new];
            }
            
            return standardProvider;
        case DMHeatmapModeDiff:
            if (!diffProvider) {
                diffProvider = [DMDiffColorProvider new];
            }
            
            return diffProvider;
    }
    
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([self isMemberOfClass:NSClassFromString(@"DMColorProvider")]) {
            [NSException raise:@"BaseClassInitializationException"
                        format:@"Attempted to initialize an abstract base class. Use +providerForMode: to obtain a subclass instance instead."];
        }
    }
    
    return self;
}

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    // TODO throw exception? - this is a base class
    // Might also be nice to just pass through to the standard color provider
}

@end
