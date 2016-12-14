
#import <MapKit/MapKit.h>
#import "MercatorTile.h"
#import "GridTileOverlayRenderer.h"
#import "DTMHeatmap.h"

static const NSInteger kSBHeatRadiusInPoints = 48;

@interface GridTileOverlayRenderer : MKTileOverlayRenderer
@property (nonatomic, readonly) float *scaleMatrix;
@property (assign) MKMapView *weakMapView;
@property (assign) DTMHeatmap *weakHeatmap;
@end
