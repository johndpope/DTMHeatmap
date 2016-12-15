#import "GridTileOverlay.h"
#import "DTMColorProvider.h"
#import "MercatorTile.h"
#import "GeoHelper.h"
#import "Geohash.h"


@interface GridTileOverlay ()
@property NSString *tilePath;
@end

@implementation GridTileOverlay


#define TILE_SIZE 256.0


//http://stackoverflow.com/questions/27418144/getting-mkmaprect-from-mktileoverlaypath/27431997#27431997
-(void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *, NSError *))result {
    NSLog(@"Loading tile x/y/z: %ld/%ld/%ld",(long)path.x,(long)path.y,(long)path.z);
    
    self.cache = YES;
    
    if(self.cache&&[self cachedTileExistsForPath:path]){
        NSData *data=[self getCachedTileForPath:path];
        if(data.length==0){
            NSLog(@"0");
        }
        result(data, nil);
        return;
    }
    
    UIImage *img = [self imageForTileX:path.x y:path.y z:path.z];
    
    // DEBUG GRID
    BOOL debugGrid = YES;
    if(debugGrid){
        
        UIImage *newImage = [self addGridTile:self.tileSize path:path image:img];
        result(UIImagePNGRepresentation(newImage),nil);
        return;
    }
    
    NSData *tileData = UIImagePNGRepresentation(img);
    [self cacheTile:tileData forPath:path];
    result(tileData,nil);
    return;

}



+(NSDictionary*)mapRectForTileX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z{
    long worldPointSize = pow(2,(int)z)*256;    // 2^10 * 256 = 262,144
    long leftEdge = x *256;                    // 12 *256  = 3,072 points
    long topEdge = y *256;                     // 256 * 8  = 2,048
    int w = pow(2,20)*256;                      // 2^20 * 256 = 268,435,456
    int zScale =  w / worldPointSize;               // 268,435,456/262,144 = 1,024
    int tileSize = 256 * zScale;                    // 256 * 1,024 = 262,144
    long x0 = leftEdge * zScale;                    // 3,072 * 1,024 = 3,145,728
    long y0 = topEdge * zScale;                     // 2,048 * 1,024 = 3,145,728
    long x1 = x0 + tileSize;
    long y1 = y0 + tileSize;
    
    MKMapPoint ul = MKMapPointMake(x0, y0);         // upper left
    MKMapPoint lr = MKMapPointMake(x1, y1);         // lower right
    MKMapRect mapRect = MKMapRectMake (fmin(ul.x, lr.x),
                                       fmin(ul.y, lr.y),
                                       fabs(ul.x - lr.x),
                                       fabs(ul.y - lr.y));
    NSValue *ulValue = [NSValue value:&ul withObjCType:@encode(MKMapPoint)];
    NSValue *lrValue = [NSValue value:&lr withObjCType:@encode(MKMapPoint)];
    
    
    NSDictionary *d0 = [NSDictionary dictionaryWithObjectsAndKeys:MKStringFromMapRect(mapRect),@"mapRect",
                        ulValue,@"ul",
                        lrValue,@"lr", nil];
    
    return d0;
    
}

+(NSString *)save:(MKMapRect)rect{
    return MKStringFromMapRect(rect);
}

+(MKMapRect)load:(NSString *)str
{
    MKMapRect mapRect;
    CGRect rect = CGRectFromString(str);
    mapRect.origin.x = rect.origin.x;
    mapRect.origin.y = rect.origin.y;
    mapRect.size.width = rect.size.width;
    mapRect.size.height = rect.size.height;
    return mapRect;
}

-(UIImage*)imageForTileX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z{
    
    
    long worldPointSize = pow(2,(int)z)*256;    // 2^10 * 256 = 262,144
    int w = self.boundingMapRect.size.width;        // 2^20 * 256 = 268,435,456
    int zScale =  w / worldPointSize;               // 268,435,456/262,144 = 1,024
    int tileSize = 256 * zScale;                    // 256 * 1,024 = 262,144
    
    double zoomScale = 256 / ceil(tileSize ); //  256 / 262144 (width) = 0.00977
    int columns =  ceil(tileSize * zoomScale);
    int rows = ceil(tileSize * zoomScale);
    int arrayLen = columns * rows;
    
    NSDictionary *d0 = [GridTileOverlay mapRectForTileX:x y:y z:z];
    MKMapRect mapRect = [GridTileOverlay load:[d0 valueForKey:@"mapRect"]];
    MKMapPoint ul;
    [[d0 valueForKey:@"ul"] getValue:&ul];
    
    
    // allocate an array matching the screen point size of the rect
    float *pointValues = calloc(arrayLen, sizeof(float));
    
    if (pointValues) {
        // pad out the mapRect with the radius on all sides.
        // we care about points that are not in (but close to) this rect
        CGRect paddedRect = CGRectMake(mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);
        paddedRect.origin.x -= kSBHeatRadiusInPoints / zoomScale;
        paddedRect.origin.y -= kSBHeatRadiusInPoints / zoomScale;
        paddedRect.size.width += 2 * kSBHeatRadiusInPoints / zoomScale;
        paddedRect.size.height += 2 * kSBHeatRadiusInPoints / zoomScale;
        
        MKMapRect paddedMapRect = MKMapRectMake(paddedRect.origin.x, paddedRect.origin.y, paddedRect.size.width, paddedRect.size.height);
        
        NSDictionary *d0 = [GeoHelper mbrGeoHashForMapRect:mapRect];
        NSString *mbr = [d0 valueForKey:@"mbr"];
        
        NSLog(@"mbr:%@",mbr);
        
        // Get the dictionary of values out of the model for this mapRect and zoomScale.
        NSDictionary *heat = [self.weakHeatmap mapPointsWithHeatInMapRect:paddedMapRect
                                                                  atScale:zoomScale];
        
        for (NSValue *key in heat) {
            // convert key to mapPoint
            MKMapPoint mapPoint;
            [key getValue:&mapPoint];
            double value = [[heat objectForKey:key] doubleValue];
            
            // figure out the correspoinding array index
            CGPoint usPoint = CGPointMake(mapPoint.x, mapPoint.y);
            
            CGPoint matrixCoord = CGPointMake((usPoint.x - ul.x) * zoomScale,
                                              (usPoint.y - ul.y) * zoomScale);
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
                            double addVal = value * self.weakRenderer.scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i];
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
        UIImage *img  =  [self imageFromBytes:rgba];
        free(rgba);
        return img;
    }
    return [[UIImage alloc]init];
}




+ (MKMapRect)mapRectForTilePath:(MKTileOverlayPath)path
{
    CGFloat xScale = (double)path.x / [self worldTileWidthForZoomLevel:path.z];
    CGFloat yScale = (double)path.y / [self worldTileWidthForZoomLevel:path.z];
    MKMapRect world = MKMapRectWorld;
    return MKMapRectMake(world.size.width * xScale,
                         world.size.height * yScale,
                         world.size.width / [self worldTileWidthForZoomLevel:path.z],
                         world.size.height / [self worldTileWidthForZoomLevel:path.z]);
}


+ (NSUInteger)worldTileWidthForZoomLevel:(NSUInteger)zoomLevel
{
    return (NSUInteger)(pow(2,zoomLevel));
}


-(UIImage *)addGridTile:(CGSize)sz path:(MKTileOverlayPath)path image:(UIImage*)img{
    
    CGRect rect = CGRectMake(0, 0, sz.width, sz.height);
    UIGraphicsBeginImageContext(sz);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [img drawInRect:rect];
    
    [[UIColor blueColor] setStroke];
    CGContextSetLineWidth(ctx, 1.0);
    CGContextStrokeRect(ctx, CGRectMake(0, 0, sz.width, sz.height));
    [[UIColor blackColor] setStroke];
    
    MKMapRect mapRect = [GridTileOverlay mapRectForTilePath:path];
    
    NSDictionary *d0 = [GeoHelper mbrGeoHashForMapRect:mapRect];
    NSString *ne = d0[@"ne"];
    NSString *nw = d0[@"nw"];
    NSString *se = d0[@"se"];
    NSString *sw = d0[@"sw"];
    NSString *mbr = d0[@"mbr"];
    
    
    NSString *text = [NSString stringWithFormat:@"X=%d Y=%d Z=%d\nne:%@ \nnw:%@ \nse:%@ \nsw:%@ \nmbr:%@ ",(int)path.x,(int)path.y,(int)path.z,ne,nw,se,sw,mbr];
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                           NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    UIImage *gridImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return gridImage;
}


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



+(NSData *)ParentTileImageSection:(NSData *)data forPath:(MKTileOverlayPath)path{
    
    
    int x=path.x%2;
    int y=path.y%2;
    
    
    UIImage *parent=[UIImage imageWithData:data];
    
    
    CGSize size=parent.size;
    
    float w=size.width/2;
    float h=size.height/2;
    
    CGRect rect=CGRectMake(0+(w*x), 0+(h*y), w, h);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([parent CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [cropped drawInRect:CGRectMake(0,0,w,h)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return UIImagePNGRepresentation(newImage);
    
}


+(MKTileOverlayPath)ParentTilePathForPath:(MKTileOverlayPath)path{
    
    MKTileOverlayPath parent;
    parent.contentScaleFactor=path.contentScaleFactor;
    parent.x=path.x/2;
    parent.y=path.y/2;
    parent.z=path.z-1;
    
    return parent;
    
}

-(bool)cachedTileExistsForPath:(MKTileOverlayPath)path{
    
    NSString *file=[self fileNameForPath:path];
    bool exists= [[NSFileManager defaultManager] fileExistsAtPath:file];
    return exists;
}

-(NSData *)getCachedTileForPath:(MKTileOverlayPath)path{
    NSString *file=[self fileNameForPath:path];
    return [[NSData alloc] initWithContentsOfFile:file];
}

-(bool)cacheTile:(NSData *)tile forPath:(MKTileOverlayPath)path{
    NSLog(@"INFO: caching tile");
    NSString *file=[self fileNameForPath:path];
    [[NSFileManager defaultManager] createFileAtPath:file contents:tile attributes:nil];
    return true;
}


-(NSString *)fileNameForPath:(MKTileOverlayPath)path{
    
    
    if(!_tilePath){
        _tilePath= [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[self uniqueId]];
    }
    
    NSString *folder=[[_tilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i", path.z]] stringByAppendingPathComponent:[NSString stringWithFormat:@"%i", (int)path.x]];
    
    bool dir;
    
    NSString *file= [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.png",(int) path.y]];
    //NSLog(file);
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:folder]){
        NSError *err;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:true attributes:nil error:&err];
        if(err){
            @throw err;
        }
    }
    
    return file;
}

-(NSString *)uniqueId{
    NSString *url=self.URLTemplate;
    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    return [[url componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
    
}

@end
