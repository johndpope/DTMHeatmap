
#import <MapKit/MapKit.h>
#import "MercatorTile.h"
#import "GridTileOverlayRenderer.h"
#import "DTMHeatmap.h"

@interface GridTileOverlay : MKTileOverlay
@property (assign) GridTileOverlayRenderer *weakRenderer;
@property (assign) DTMHeatmap *weakHeatmap;
@property (assign) MKMapView *weakMapView;
 @property bool cache;
@end
