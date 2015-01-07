//
//  DMHeatmapRenderer.m
//  HeatMapTest
//
//  Created by Bryan Oltman on 1/6/15.
//  Copyright (c) 2015 Bryan Oltman. All rights reserved.
//

#import "DMHeatmapRenderer.h"

// This sets the spread of the heat from each map point (in screen pts.)
static const NSInteger kSBHeatRadiusInPoints = 48;

// These affect the transparency of the heatmap
// Colder areas will be more transparent
// Currently the alpha is a two piece linear function of the value
// Play with the pivot point and max alpha to affect the look of the heatmap

// This number should be between 0 and 1
static const CGFloat kSBAlphaPivotX = 0.333;

// This number should be between 0 and MAX_ALPHA
static const CGFloat kSBAlphaPivotY = 0.5;

// This number should be between 0 and 1
static const CGFloat kSBMaxAlpha = 0.85;

@interface DMHeatmapRenderer ()
@property (nonatomic, readonly) float *scaleMatrix;
@end

@implementation DMHeatmapRenderer

@synthesize scaleMatrix = _scaleMatrix;

- (id)initWithOverlay:(id <MKOverlay>)overlay
{
    if (self = [super initWithOverlay:overlay]) {
        _scaleMatrix = malloc(2 * kSBHeatRadiusInPoints * 2 * kSBHeatRadiusInPoints * sizeof(float));
        [self populateScaleMatrix];
    }
    
    return self;
}

- (void)populateScaleMatrix
{
    for(int i = 0; i < 2 * kSBHeatRadiusInPoints; i++) {
        for(int j = 0; j < 2 * kSBHeatRadiusInPoints; j++) {
            float distance = sqrt((i - kSBHeatRadiusInPoints) * (i - kSBHeatRadiusInPoints) + (j - kSBHeatRadiusInPoints) * (j - kSBHeatRadiusInPoints));
            float scaleFactor = 1 - distance / kSBHeatRadiusInPoints;
            if (scaleFactor < 0) {
                scaleFactor = 0;
            } else {
                scaleFactor = (expf(-distance/10.0) - expf(-kSBHeatRadiusInPoints/10.0)) / expf(0);
            }
            
            _scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i] = scaleFactor;
        }
    }
}

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    if (value > 1) {
        value = 1;
    }
    
    value = sqrt(value);
    
    if (value < kSBAlphaPivotY) {
        *alpha = value * kSBAlphaPivotY / kSBAlphaPivotX;
    } else {
        *alpha = kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX);
    }
    
    //formula converts a number from 0 to 1.0 to an rgb color.
    //uses MATLAB/Octave colorbar code
    if(value <= 0) {
        *red = *green = *blue = *alpha = 0;
    } else if(value < 0.125) {
        *red = *green = 0;
        *blue = 4 * (value + 0.125);
    } else if(value < 0.375) {
        *red = 0;
        *green = 4 * (value - 0.125);
        *blue = 1;
    } else if(value < 0.625) {
        *red = 4 * (value - 0.375);
        *green = 1;
        *blue = 1 - 4 * (value - 0.375);
    } else if(value < 0.875) {
        *red = 1;
        *green = 1 - 4 * (value - 0.625);
        *blue = 0;
    } else {
        *red = MAX(1 - 4 * (value - 0.875), 0.5);
        *green = *blue = 0;
    }
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{
    CGRect usRect = [self rectForMapRect:mapRect]; //rect in user space coordinates (NOTE: not in screen points)
    MKMapRect visibleRect = [self.overlay boundingMapRect];
    MKMapRect mapIntersect = MKMapRectIntersection(mapRect, visibleRect);
    CGRect usIntersect = [self rectForMapRect:mapIntersect]; //rect in user space coordinates (NOTE: not in screen points)
    
    int columns = ceil(CGRectGetWidth(usRect) * zoomScale);
    int rows = ceil(CGRectGetHeight(usRect) * zoomScale);
    int arrayLen = columns * rows;
    
    //allocate an array matching the screen point size of the rect
    float *pointValues = calloc(arrayLen, sizeof(float));
    
    if (pointValues) {
        //pad out the mapRect with the radius on all sides.
        // we care about points that are not in (but close to) this rect
        CGRect paddedRect = [self rectForMapRect:mapRect];
        paddedRect.origin.x -= kSBHeatRadiusInPoints / zoomScale;
        paddedRect.origin.y -= kSBHeatRadiusInPoints / zoomScale;
        paddedRect.size.width += 2 * kSBHeatRadiusInPoints / zoomScale;
        paddedRect.size.height += 2 * kSBHeatRadiusInPoints / zoomScale;
        MKMapRect paddedMapRect = [self mapRectForRect:paddedRect];
        
        //Get the dictionary of values out of the model for this mapRect and zoomScale.
        DMHeatmap *hm = (DMHeatmap *)self.overlay;
        NSDictionary *heat = [hm mapPointsWithHeatInMapRect:paddedMapRect atScale:zoomScale];
        
        for (NSValue *key in heat) {
            //convert key to mapPoint
            MKMapPoint mapPoint;
            [key getValue:&mapPoint];
            double value = [[heat objectForKey:key] doubleValue];
            
            //figure out the correspoinding array index
            CGPoint usPoint = [self pointForMapPoint:mapPoint];
            
            CGPoint matrixCoord = CGPointMake((usPoint.x - usRect.origin.x) * zoomScale,
                                              (usPoint.y - usRect.origin.y) * zoomScale);
            
            if (value > 0) { //don't bother with 0 or negative values
                //iterate through surrounding pixels and increase
                for(int i = 0; i < 2 * kSBHeatRadiusInPoints; i++) {
                    for(int j = 0; j < 2 * kSBHeatRadiusInPoints; j++) {
                        //find the array index
                        int column = floor(matrixCoord.x - kSBHeatRadiusInPoints + i);
                        int row = floor(matrixCoord.y - kSBHeatRadiusInPoints + j);
                        
                        //make sure this is a valid array index
                        if(row >= 0 && column >= 0 && row < rows && column < columns) {
                            int index = columns * row + column;
                            pointValues[index] += value * _scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i];
                        }
                    }
                }
            }
        }
        
        CGFloat red, green, blue, alpha;
        uint indexOrigin;
        unsigned char *rgba = (unsigned char *)calloc(columns * rows * 4, sizeof(unsigned char));
        int arrayLen = columns * rows;
        for (int i = 0; i < arrayLen; i++) {
            if (pointValues[i] > 0) {
                indexOrigin = 4*i;
                [self colorForValue:pointValues[i]
                                red:&red
                              green:&green
                               blue:&blue
                              alpha:&alpha];
                
                rgba[indexOrigin] = red * 255 * alpha;
                rgba[indexOrigin+1] = green * 255 * alpha;
                rgba[indexOrigin+2] = blue * 255 * alpha;
                rgba[indexOrigin+3] = alpha * 255;
            }
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext = CGBitmapContextCreate(rgba,
                                                           columns,
                                                           rows,
                                                           8, // bitsPerComponent
                                                           4 * columns, // bytesPerRow
                                                           colorSpace,
                                                           kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
        UIImage *img = [UIImage imageWithCGImage:cgImage];
        CFRelease(colorSpace);
        CFRelease(cgImage);
        CFRelease(bitmapContext);
        free(rgba);
        free(pointValues);
        
        UIGraphicsPushContext(context);
        [img drawInRect:usIntersect];
        UIGraphicsPopContext();
    }
}

- (void)dealloc
{
    free(_scaleMatrix);
}

@end
