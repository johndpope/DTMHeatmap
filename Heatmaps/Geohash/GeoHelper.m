

#import "GeoHelper.h"
#import "GeoHash.h"

@implementation GeoHelper


+(NSString*)geoHashForMapRect:(MKMapRect)mapRect size:(int)size{
    NSDictionary *d0 = [self hashGridForMapRect:mapRect];
    __block NSString *geohash = @"";
    NSArray *array = [(NSSet*)[d0 valueForKey:@"mbr"] allObjects];
    geohash = [array objectAtIndex:0];
   [array enumerateObjectsUsingBlock:^(NSString *gHash, NSUInteger idx, BOOL * _Nonnull stop) {
       if (gHash.length == size) {
           geohash = gHash;
       }
   }];


    return [geohash substringWithRange:NSMakeRange(0, 1)];
  
    
}
+(NSBag*)hashBagForMapRect:(MKMapRect)mapRect{
    return [[self hashGridForMapRect:mapRect] valueForKey:@"mbr"];
}

+(NSDictionary*)hashGridForMapRect:(MKMapRect)mapRect{
    
    CLLocationCoordinate2D ne =  [GeoHelper getNECoordinate:mapRect];
    CLLocationCoordinate2D nw =  [GeoHelper getNWCoordinate:mapRect];
    CLLocationCoordinate2D se =  [GeoHelper getSECoordinate:mapRect];
    CLLocationCoordinate2D sw =  [GeoHelper getSWCoordinate:mapRect];
    
    int hashLength = 12;
    NSString *neHash = [GeoHash hashForLatitude:ne.latitude
                                      longitude:ne.longitude
                                         length:hashLength];
    NSString *nwHash = [GeoHash hashForLatitude:nw.latitude
                                      longitude:nw.longitude
                                         length:hashLength];
    NSString *seHash = [GeoHash hashForLatitude:se.latitude
                                      longitude:se.longitude
                                         length:hashLength];
    NSString *swHash = [GeoHash hashForLatitude:sw.latitude
                                      longitude:sw.longitude
                                         length:hashLength];
    
 
    NSBag *bag = [NSBag bag];
   
    [bag add:[neHash substringToIndex:1]];
    [bag add:[nwHash substringToIndex:1]];
    [bag add:[seHash substringToIndex:1]];
    [bag add:[swHash substringToIndex:1]];
    
    
    [bag add:[neHash substringToIndex:2]];
    [bag add:[nwHash substringToIndex:2]];
    [bag add:[seHash substringToIndex:2]];
    [bag add:[swHash substringToIndex:2]];
    
    //NSLog(@"bag:%@",[bag internalDictionary]);
    
    NSDictionary *d0 = [NSDictionary dictionaryWithObjectsAndKeys:
                        neHash,@"ne",
                        nwHash,@"nw",
                        seHash,@"se",
                        swHash,@"sw",
                        bag,@"mbr",nil];
    return d0;
}
+(CLLocationCoordinate2D)getNECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:mRect.origin.y];
}
+(CLLocationCoordinate2D)getNWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMinX(mRect) y:mRect.origin.y];
}
+(CLLocationCoordinate2D)getSECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:MKMapRectGetMaxY(mRect)];
}
+(CLLocationCoordinate2D)getSWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:mRect.origin.x y:MKMapRectGetMaxY(mRect)];
}
+(CLLocationCoordinate2D)getCoordinateFromMapRectanglePoint:(double)x y:(double)y{
    MKMapPoint swMapPoint = MKMapPointMake(x, y);
    return MKCoordinateForMapPoint(swMapPoint);
}

@end
