
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GeoHelper : NSObject
+(NSDictionary*)mbrGeoHashForMapRect:(MKMapRect)mapRect;
+(CLLocationCoordinate2D)getNECoordinate:(MKMapRect)mRect;
+(CLLocationCoordinate2D)getNWCoordinate:(MKMapRect)mRect;
+(CLLocationCoordinate2D)getSECoordinate:(MKMapRect)mRect;
+(CLLocationCoordinate2D)getSWCoordinate:(MKMapRect)mRect;
@end
