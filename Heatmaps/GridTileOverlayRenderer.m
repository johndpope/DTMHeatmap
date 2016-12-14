
#import "GridTileOverlayRenderer.h"
#import <MapKit/MapKit.h>
#import "DTMColorProvider.h"

// This sets the spread of the heat from each map point (in screen pts.)


@interface GridTileOverlayRenderer ()

@end

@implementation GridTileOverlayRenderer

- (id)initWithOverlay:(id <MKOverlay>)overlay
{
    if (self = [super initWithOverlay:overlay]) {
        _scaleMatrix = malloc(2 * kSBHeatRadiusInPoints * 2 * kSBHeatRadiusInPoints * sizeof(float));
        [self populateScaleMatrix];
    }
    
    return self;
}

- (void)dealloc
{
    free(_scaleMatrix);
}

- (void)populateScaleMatrix
{
    for (int i = 0; i < 2 * kSBHeatRadiusInPoints; i++) {
        for (int j = 0; j < 2 * kSBHeatRadiusInPoints; j++) {
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

/*
N.B.  Enabling this will DISABLE/override the GridTileOverlay drawing!!!
-(void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    
    if(1){
        NSLog(@"Rendering at (x,y):(%f,%f) with size (w,h):(%f,%f) zoom :%f",mapRect.origin.x,mapRect.origin.y,mapRect.size.width,mapRect.size.height,zoomScale);
        CGRect rect = [self rectForMapRect:mapRect];
        NSLog(@"CGRect: %@",NSStringFromCGRect(rect));
        NSLog(@"bounding rect: %@",MKStringFromMapRect([self.overlay boundingMapRect]));
        
        MKTileOverlayPath path;
        MKTileOverlay *tileOverlay = (MKTileOverlay *)self.overlay;
        path.x = mapRect.origin.x*zoomScale/tileOverlay.tileSize.width;
        path.y = mapRect.origin.y*zoomScale/tileOverlay.tileSize.width;
        path.z = log2(zoomScale)+20;
        
        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
        CGContextSetLineWidth(context, 1.0/zoomScale);
        CGContextStrokeRect(context, rect);
        
        UIGraphicsPushContext(context);
        NSString *text = [NSString stringWithFormat:@"X=%d\nY=%d\nZ=%d",(int)path.x,(int)path.y,(int)path.z];
        [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20.0/zoomScale],
                                               NSForegroundColorAttributeName:[UIColor blackColor]}];
        UIGraphicsPopContext();
 
    }
    
    if(0){
        MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
        MKMapRect boundingRect = MKMapRectForCoordinateRegion(region);
        NSLog(@">>boundingRect: %@\n ", MKStringFromMapRect(boundingRect));
        
        //long2tilex
        CGRect usRect = [self rectForMapRect:mapRect]; //rect in user space coordinates (NOTE: not in screen points)
        NSLog(@">>drawMapRect: %@\n ", MKStringFromMapRect(mapRect));
        MKMapRect visibleRect = [self.overlay boundingMapRect];
        NSLog(@">>visibleRect: %@\n ",    MKStringFromMapRect(visibleRect));
        MKMapRect mapIntersect = MKMapRectIntersection(mapRect, visibleRect);
        NSLog(@">>mapIntersect: %@\n ",  MKStringFromMapRect(mapIntersect));
        CGRect usIntersect = [self rectForMapRect:mapIntersect]; //rect in user space coordinates (NOTE: not in screen points)
        NSLog(@"usIntersect: %@\n ",  NSStringFromCGRect(usIntersect));
        NSLog(@"usRect: %@\n ",    NSStringFromCGRect(usRect));
        NSLog(@"zoomScale: %.2f\n ",zoomScale);
        
        
        int columns = ceil(CGRectGetWidth(usRect) * zoomScale); //256
        int rows = ceil(CGRectGetHeight(usRect) * zoomScale); //256
        int arrayLen = columns * rows;
        
        NSLog(@"columns: %d\n ",  columns);
        NSLog(@"rows: %d\n ",  rows);
        NSLog(@"arrayLen: %d\n ",  arrayLen);
        
        // allocate an array matching the screen point size of the rect
        float *pointValues = calloc(arrayLen, sizeof(float));
        
        if (pointValues) {
            // pad out the mapRect with the radius on all sides.
            // we care about points that are not in (but close to) this rect
            CGRect paddedRect = [self rectForMapRect:mapRect];
            paddedRect.origin.x -= kSBHeatRadiusInPoints / zoomScale;
            paddedRect.origin.y -= kSBHeatRadiusInPoints / zoomScale;
            paddedRect.size.width += 2 * kSBHeatRadiusInPoints / zoomScale;
            paddedRect.size.height += 2 * kSBHeatRadiusInPoints / zoomScale;
            MKMapRect paddedMapRect = [self mapRectForRect:paddedRect];
            
            // Get the dictionary of values out of the model for this mapRect and zoomScale.
            DTMHeatmap *hm = (DTMHeatmap *)self.overlay;
            NSDictionary *heat = [self.weakHeatmap mapPointsWithHeatInMapRect:paddedMapRect
                                                                      atScale:zoomScale];
            
            for (NSValue *key in heat) {
                // convert key to mapPoint
                MKMapPoint mapPoint;
                [key getValue:&mapPoint];
                double value = [[heat objectForKey:key] doubleValue];
                
                // figure out the correspoinding array index
                CGPoint usPoint = [self pointForMapPoint:mapPoint];
                
                CGPoint matrixCoord = CGPointMake((usPoint.x - usRect.origin.x) * zoomScale,
                                                  (usPoint.y - usRect.origin.y) * zoomScale);
                
                if (value != 0 && !isnan(value)) { // don't bother with 0 or NaN
                    // iterate through surrounding pixels and increase
                    for (int i = 0; i < 2 * kSBHeatRadiusInPoints; i++) {
                        for (int j = 0; j < 2 * kSBHeatRadiusInPoints; j++) {
                            // find the array index
                            int column = floor(matrixCoord.x - kSBHeatRadiusInPoints + i);
                            int row = floor(matrixCoord.y - kSBHeatRadiusInPoints + j);
                            
                            // make sure this is a valid array index
                            if (row >= 0 && column >= 0 && row < rows && column < columns) {
                                int index = columns * row + column;
                                double addVal = value * _scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i];
                                pointValues[index] += addVal;
                            }
                        }
                    }
                }
            }
            
            CGFloat red, green, blue, alpha;
            uint indexOrigin;
            unsigned char *rgba = (unsigned char *)calloc(arrayLen * 4, sizeof(unsigned char));
            DTMColorProvider *colorProvider = [self.weakHeatmap colorProvider];
            for (int i = 0; i < arrayLen; i++) {
                if (pointValues[i] != 0) {
                    indexOrigin = 4 * i;
                    [colorProvider colorForValue:pointValues[i]
                                             red:&red
                                           green:&green
                                            blue:&blue
                                           alpha:&alpha];
                    
                    rgba[indexOrigin] = red;
                    rgba[indexOrigin + 1] = green;
                    rgba[indexOrigin + 2] = blue;
                    rgba[indexOrigin + 3] = alpha;
                }
            }
            
            free(pointValues);
            
            
            UIImage *img = [self imageFromBytes:rgba];
            free(rgba);
            
            UIGraphicsPushContext(context);
            [img drawInRect:usRect];
            UIGraphicsPopContext();

            
        }
    }
    
}*/

- (UIImage*) imageFromBytes:(unsigned char *)bytes {
    const int WIDTH = 256;
    const int HEIGHT = 256;
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext=CGBitmapContextCreate(bytes, WIDTH, HEIGHT, 8, 4*WIDTH, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CFRelease(colorSpace);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    
    UIImage * newimage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return newimage;
}

@end
