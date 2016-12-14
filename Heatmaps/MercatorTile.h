
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MercatorTile : NSObject


/** A rectangular area as measured on a two-dimensional map projection. */
typedef struct MGLCoordinateBounds {
    /** Coordinate at the southwest corner. */
    CLLocationCoordinate2D sw;
    /** Coordinate at the northeast corner. */
    CLLocationCoordinate2D ne;
} MGLCoordinateBounds;

MGLCoordinateBounds boundsFromXYZ(int x, int y, int z);

int long2tilex(double lon, int z);
int lat2tiley(double lat, int z);

double tilex2long(int x, int z);
double tiley2lat(int y, int z);

CLLocationCoordinate2D coordinate(int x, int y, int z);
MKMapRect mapRectFor(int x, int y, int z);
-(NSArray*)tilesForBounds:(MGLCoordinateBounds)bounds
                  minZoom:(int)minZoom
                  maxZoom:(int)maxZoom;
-(NSArray*)xyz:(MGLCoordinateBounds)bounds zoom:(int)zoom;

MKMapRect MKMapRectForCoordinateRegion(MKCoordinateRegion region);
@end
