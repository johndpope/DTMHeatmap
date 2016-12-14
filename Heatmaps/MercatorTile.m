

#import "MercatorTile.h"


@implementation MercatorTile



const int R = 6378137;
double sphericalScale = 0.5 / (M_PI * R);
const int tileSize = 256;



-(void)doIt{
    
    
    MGLCoordinateBounds bounds;
    bounds.sw = CLLocationCoordinate2DMake(40.64417760251725,-74.00596618652344);
    bounds.ne = CLLocationCoordinate2DMake(40.797957124643666,-73.90502929687499);
    NSArray *tiles = [self xyz:bounds zoom:13];
    NSLog(@"tiles:%@",tiles);
}



//pyramid of tiles
-(NSArray*)tilesForBounds:(MGLCoordinateBounds)bounds
                  minZoom:(int)minZoom
                  maxZoom:(int)maxZoom{
    
    int min;
    int max;
    NSMutableArray* tiles = [NSMutableArray array];
    
    if (!maxZoom) {
        max = min = minZoom;
    } else if (maxZoom < minZoom) {
        min = maxZoom;
        max = minZoom;
    } else {
        min = minZoom;
        max = maxZoom;
    }
    
    for (int z = min; z <= max; z++) {
        NSArray *toAdd = [self xyz:bounds zoom:z];
        [tiles addObjectsFromArray:toAdd];
    }
    
    return tiles;
    
};


-(NSArray*)xyz:(MGLCoordinateBounds)bounds zoom:(int)zoom {
    
    
    CGPoint sw  = [self projectForLat:bounds.sw.latitude  lng:bounds.sw.longitude zoom:zoom];
    
    CGPoint ne  =  [self projectForLat:bounds.ne.latitude  lng:bounds.ne.longitude zoom:zoom];
    NSMutableArray *tiles = [NSMutableArray array];
    
    for (int x = sw.x; x <= ne.x; x++) {
        for (int y = ne.y ; y <= sw.y; y++) {
            MGLCoordinateBounds bbox = boundsFromXYZ(x,y,zoom);
            NSString *urlKN = [NSString stringWithFormat:@"%f,%f,%f,%f",
                               bbox.sw.latitude, bbox.sw.longitude,bbox.ne.latitude,bbox.ne.longitude];
            NSDictionary *d0 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                [NSNumber numberWithInt:x],@"x",
                                [NSNumber numberWithInt:y],@"y",
                                [NSNumber numberWithInt:zoom],@"z",
                                urlKN,@"bbox",
                                nil];
            
            [tiles addObject:d0];
            
        }
    }
    
    return tiles;
    
}


-(CGPoint)projectForLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng zoom:(double)zoom {
    double d = M_PI / 180;
    double max = 1 - 1E-15;
    double sin1 = MAX(MIN(sin(lat * d), max), -max);
    double scale = tileSize * pow(2, zoom);
    
    CGPoint point = CGPointMake( R * lng * d, R * log((1 + sin1) / (1 - sin1)) / 2) ;
    
    double x0 = (scale * (sphericalScale * point.x + 0.5));
    double y0 = (scale * (-sphericalScale * point.y + 0.5));
    
    point.x = [self tiled:x0];
    point.y = [self tiled:y0];
    return point;
}

-(double) tiled:(int)num {
    return floor(num/tileSize);
}




double xOfColumn(NSInteger column,NSInteger zoom){
    
    double x = column;
    double z = zoom;
    
    return x / pow(2.0, z) * 360.0 - 180;
}

double yOfRow(NSInteger row,NSInteger zoom){
    
    double y = row;
    double z = zoom;
    
    double n = M_PI - 2.0 * M_PI * y / pow(2.0, z);
    return 180.0 / M_PI * atan(0.5 * (exp(n) - exp(-n)));
}


double MercatorXofLongitude(double lon){
    return  lon * 20037508.34 / 180;
}

double MercatorYofLatitude(double lat){
    double y = log(tan((90 + lat) * M_PI / 360)) / (M_PI / 180);
    y = y * 20037508.34 / 180;
    
    return y;
}

int long2tilex(double lon, int z)
{
    return (int)(floor((lon + 180.0) / 360.0 * pow(2.0, z)));
}

int lat2tiley(double lat, int z)
{
    return (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, z)));
}

double tilex2long(int x, int z)
{
    return x / pow(2.0, z) * 360.0 - 180;
}

double tiley2lat(int y, int z)
{
    double n = M_PI - 2.0 * M_PI * y / pow(2.0, z);
    return 180.0 / M_PI * atan(0.5 * (exp(n) - exp(-n)));
}


CLLocationCoordinate2D coordinate(int x, int y, int z){
    double lng = tilex2long(x,z);
    double lat = tiley2lat(y,z);
    
    return CLLocationCoordinate2DMake(lat, lng);
}


MKMapPoint point(int x, int y, int z){
    double lng = tilex2long(x,z);
    double lat = tiley2lat(y,z);
    return MKMapPointForCoordinate(CLLocationCoordinate2DMake(lat, lng));
}


/*MKMapRect mapRectFor(int x, int y, int z){
    MKMapPoint ul = point(x,y,z);
    MKMapPoint lr = point(x+1,y+1,z);
    
    MKMapRect rect1 = MKMapRectMake(ul.x, ul.y, 0, 0);
    MKMapRect rect2 = MKMapRectMake(lr.x, lr.y, 0, 0);
    return MKMapRectUnion(rect1, rect2);
}*/

/*MKMapRect mapRectFor(int x, int y, int z){
    int worldPointSize = pow(2,z)*256;              // 2^10 * 256 = 262,144
    int tilesOnASide = pow(2,z);                    // 2^10 = 1,024
    long leftEdge = x * 256;                    // 12 *256  = 3,072 points
    long topEdge = y * 256;                     // 256 * 8  = 2,048
    int w = self.boundingMapRect.size.width;        // 2^20 * 256 = 268,435,456
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
    return mapRect;
}*/



MGLCoordinateBounds boundsFromXYZ(int x, int y, int z){
    MGLCoordinateBounds bounds;
    bounds.sw = coordinate(x,y,z);
    bounds.ne = coordinate(x+1,y+1,z);;
    return bounds;
}

MKMapRect MKMapRectForCoordinateRegion(MKCoordinateRegion region)
{
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

@end
