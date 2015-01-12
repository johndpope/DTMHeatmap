//
//  ColorProvider.m
//  DMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMColorProvider.h"

@implementation DMColorProvider

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
