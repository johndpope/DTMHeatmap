

#import "GeoHelper.h"
#import "GeoHash.h"


@implementation GeoHelper

+(NSDictionary*)mbrGeoHashForMapRect:(MKMapRect)mapRect{
    
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
    
    NSLog(@"ne:%@",neHash);
    NSLog(@"nw:%@",nwHash);
    NSLog(@"se:%@",seHash);
    NSLog(@"sw:%@",swHash);
    
    __block NSString *mbrHash = @"";
    [neHash enumerateSubstringsInRange:NSMakeRange(0, neHash.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        
        NSString *str = [neHash substringToIndex:substringRange.location];
        if ([nwHash componentsSeparatedByString:str].count >1) {
            mbrHash = str;
            if ([seHash componentsSeparatedByString:str].count >1) {
                mbrHash = str;
                if ([swHash componentsSeparatedByString:str].count>1) {
                    mbrHash = str;
                }
            }
        }
    }] ;
    
    NSDictionary *d0 = [NSDictionary dictionaryWithObjectsAndKeys:
                        neHash,@"ne",
                        nwHash,@"nw",
                        seHash,@"se",
                        swHash,@"sw",
                        mbrHash,@"mbr",nil];
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
