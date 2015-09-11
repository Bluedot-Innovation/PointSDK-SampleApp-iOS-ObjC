//
//  BDZoneMapViewController.m
//  BDPoint
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <BDPointSDK.h>

#import "EXZoneMapViewController.h"
#import "EXNotificationStrings.h"

//  Declare constants
static float  mapInset = 10.0f;
static float  minButtonHeight = 44.0f;


/*
 *  Anonymous category for local properties.
 */
@interface EXZoneMapViewController () <MKMapViewDelegate>

@property (nonatomic, readonly) MKMapView  *mapView;
@property (nonatomic) BDPointOverlayRendererFactory  *pointOverlayRendererFactory;

@property (nonatomic) NSCache  *overlayRendererCache;
@property (nonatomic) NSMapTable  *fenceCheckInStatuses;
@property (nonatomic) NSMapTable  *beaconCheckInStatuses;
@property (nonatomic) id<BDPSpatialObjectInfo>  lastCheckedInSpatialObject;

@property (nonatomic) UIEdgeInsets mapInsets;

@end


@implementation EXZoneMapViewController
{
    UIColor  *spatialObjectColourDefault;
    UIColor  *spatialObjectColourCheckedIn;
    UIColor  *spatialObjectColourCheckedInLast;
    
    MKMapView  *_mapView;
    float  _windowHeight;
}


- (id)init
{
    //  Create the view utilising the height of the main screen
    return( [ self initWithHeight: UIScreen.mainScreen.bounds.size.height ] );
}

- (id)initWithHeight: (float)height
{
    
    if ( ( self = [super init] ) != nil )
    {
        //  Set the view properties
        self.title = @"Map";
        _windowHeight = height;
        
        //  Set the colours to use for the Checked-In state of spatial objects (fences and beacons)
        spatialObjectColourDefault = UIColor.grayColor;
        spatialObjectColourCheckedIn = UIColor.cyanColor;
        spatialObjectColourCheckedInLast = UIColor.greenColor;
        
        //  Store the fences that have been checked into
        _fenceCheckInStatuses = [ [ NSMapTable alloc ] initWithKeyOptions: NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality
                                                             valueOptions: NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality
                                                                 capacity: 8 ];
        
        _beaconCheckInStatuses = [ [ NSMapTable alloc ] initWithKeyOptions: NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality
                                                              valueOptions: NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality
                                                                  capacity: 8 ];

        _pointOverlayRendererFactory = [ BDPointOverlayRendererFactory sharedInstance ];
        _overlayRendererCache = [ NSCache new ];

        _mapInsets = UIEdgeInsetsMake( mapInset, mapInset, mapInset, mapInset );

        //  Create the handler for dealing with notifications raised from other view controllers
        void ( ^showZonesNotificationHandler)(NSNotification *) = ^( NSNotification *showZonesNotification )
        {
            MKMapRect showMapRect;
            id showObject = showZonesNotification.object;
            
            if( [ showObject isKindOfClass: BDZoneInfo.class ] )
            {
                showMapRect = [ self.mapView mapRectForZone: (BDZoneInfo*) showObject ];
            }
            else if( [ showObject conformsToProtocol: @protocol(BDPSpatialObjectInfo) ] )
            {
                showMapRect = [ self.mapView mapRectForSpatialObject: (id<BDPSpatialObjectInfo>) showObject ];
            }
            else
            {
                showMapRect = MKMapRectWorld;
            }
            
            [ self.mapView setVisibleMapRect: showMapRect
                                 edgePadding: _mapInsets
                                    animated: YES ];
        };

        [ NSNotificationCenter.defaultCenter addObserverForName: EXShowFencesOnMapNotification
                                                         object: nil
                                                          queue: NSOperationQueue.mainQueue
                                                     usingBlock: showZonesNotificationHandler];
    }
    
    return self;
}


/*
 *  Over-ride the loadView to programmatically setup the view.
 */
- (void)loadView
{
    CGRect  size = { 0.0f, 0.0f, UIScreen.mainScreen.bounds.size.width, _windowHeight };
    
    _mapView = [ [ MKMapView alloc ] initWithFrame: size ];

    //  Using showUserLocation will use continuous GPS
    _mapView.showsUserLocation = NO;
    _mapView.delegate = self;

    self.view = _mapView;
    [ self.view addSubview: [ self createShowLocationButton ] ];
}


- (MKMapView *)mapView
{
    return (MKMapView *)self.view;
}


- (void)setZones: (NSSet *)zones
{
    // Remove existing overlays from the previous Zones
    [ self.mapView removeAllSpatialObjectOverlays];
    
    // Clear check-in statuses for the previous Fences and Beacons
    {
        [ _fenceCheckInStatuses  removeAllObjects ];
        [ _beaconCheckInStatuses removeAllObjects ];
        
        _lastCheckedInSpatialObject = nil;
    }
    
    _zones = zones;
    
    // Set-up a check-in status for each Fence and Beacon
    {
        for( BDZoneInfo *zone in zones )
        {
            for( BDFenceInfo *fence in zone.fences )
            {
                [ _fenceCheckInStatuses setObject: @(NO) forKey: fence ];
            }
            
            for( BDBeaconInfo *beacon in zone.beacons )
            {
                [ _beaconCheckInStatuses setObject: @(NO) forKey: beacon ];
            }
        }
    }
    
    // Add new map overlays from the new Zones
    {
        UIImage *beaconIconImage = [ UIImage imageNamed: @"BeaconIcon" ];
        
        [ self.mapView addOverlaysForZones: zones
                       withBeaconIconImage: beaconIconImage
                           beaconIconScale: 2.0 ];
    }
    
    [ self zoomToFitZones ];
}


/*
 *  A beacon has been checked into; highlight the proximity range of the beacon as the latest check-in and
 *  update the colour tinting of any previously checked-in beacon.
 */
- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon
{
    BDBeaconInfo  *prevCheckIn = _lastCheckedInSpatialObject;
    
    [ _beaconCheckInStatuses setObject: @(YES) forKey: beacon ];
    _lastCheckedInSpatialObject = beacon;
    
    [ self.mapView setTintColor: [ self tintColorForSpatialObject: beacon ] forSpatialObject: beacon ];
    
    if ( prevCheckIn != nil )
    {
        [ self.mapView setTintColor: [ self tintColorForSpatialObject: prevCheckIn ] forSpatialObject: prevCheckIn ];
    }
}

/*
 *  A fence has been checked into; highlight this fence as the latest check-in and update the colour tinting of any
 *  previously checked-in fence.
 */
- (void)didCheckIntoFence: (BDFenceInfo *)fence
{
    BDFenceInfo  *prevCheckIn = _lastCheckedInSpatialObject;
    
    [ _fenceCheckInStatuses setObject: @(YES) forKey: fence ];
    _lastCheckedInSpatialObject = fence;
    
    [ self.mapView setTintColor: [ self tintColorForSpatialObject: fence ] forSpatialObject: fence ];
    
    if ( prevCheckIn != nil )
    {
        [ self.mapView setTintColor: [ self tintColorForSpatialObject: prevCheckIn ] forSpatialObject: prevCheckIn ];
    }
}


/*
 *  Zoom to the level required to map view to encompass the configured zones.
 */
- (void)zoomToFitZones
{
    MKMapRect zonesMapRect = [ self.mapView mapRectForZones: _zones ];
    
    [ self.mapView setVisibleMapRect: zonesMapRect
                         edgePadding: _mapInsets
                            animated: YES ];
}


#pragma mark MKMapViewDelegate begin

- (MKOverlayRenderer *)mapView: (MKMapView *)mapView
            rendererForOverlay: (id<MKOverlay>)overlay
{
    MKOverlayRenderer *renderer = [ _overlayRendererCache objectForKey: overlay ];
    
    if( renderer == nil )
    {
        BDPointOverlayRendererFactory *rendererFactory = BDPointOverlayRendererFactory.sharedInstance;
        
        if( [ rendererFactory isPointOverlay: overlay ] )
        {
            renderer = [ rendererFactory rendererForOverlay: overlay ];
            
            [ _overlayRendererCache setObject: renderer
                                       forKey: overlay ];
        }
    }

    return renderer;
}

#pragma mark MKMapViewDelegate end


/*
 *  Determine if a fence has been checked into.
 */
- (BOOL)hasCheckedIntoFence:(BDFenceInfo *)fence
{
    return [ (NSNumber *)[ _fenceCheckInStatuses objectForKey: fence ] boolValue ];
}

/*
 *  Determine if a beacon has been checked into.
 */
- (BOOL)hasCheckedIntoBeacon:(BDBeaconInfo *)beacon
{
    return [ (NSNumber *)[ _beaconCheckInStatuses objectForKey: beacon ] boolValue ];
}


/*
 *  Determine the tint colour for a spatial object (either a BDBeaconInfo or a BDFenceInfo).
 */
- (UIColor*)tintColorForSpatialObject: (id<BDPSpatialObjectInfo>)spatialObject
{
    UIColor  *stateColor;
    
    if ( spatialObject == _lastCheckedInSpatialObject )
    {
        stateColor = spatialObjectColourCheckedInLast;
    }
    else if ( [ spatialObject isKindOfClass: BDFenceInfo.class ] && [ self hasCheckedIntoFence: (BDFenceInfo *)spatialObject ] == YES )
    {
        stateColor = spatialObjectColourCheckedIn;
    }
    else if ( [ spatialObject isKindOfClass: BDBeaconInfo.class ] && [ self hasCheckedIntoBeacon: (BDBeaconInfo *)spatialObject ] == YES )
    {
        stateColor = spatialObjectColourCheckedIn;
    }
    else
    {
        stateColor = spatialObjectColourDefault;
    }
    
    return stateColor;
}


/*
 *  Create a button to show the location of the device at the current accuracy.
 */
- (UIButton *)createShowLocationButton
{
    float  buttonHeight = ( _windowHeight / 10.0f );
    UIButton  *showLocationButton = [ UIButton buttonWithType: UIButtonTypeRoundedRect ];
    
    
    //  Ensure the minimum button height
    if ( buttonHeight < minButtonHeight )
    {
        buttonHeight = minButtonHeight;
    }
    
    //  Setup the button criteria
    showLocationButton.frame = CGRectMake( mapInset, _windowHeight - buttonHeight - mapInset, self.view.frame.size.width - ( mapInset * 2.0f ), buttonHeight );

    showLocationButton.layer.cornerRadius = 6.0f;
    showLocationButton.layer.borderWidth = 1.5f;
    showLocationButton.layer.borderColor = [ [ UIColor colorWithRed:  66.0f / 255.0f
                                                              green: 155.0f / 255.0f
                                                               blue: 213.0f / 255.0f
                                                              alpha: 1.0f ] CGColor ];

    showLocationButton.backgroundColor = [ UIColor colorWithRed: 66.0f / 255.0f
                                                          green: 155.0f / 255.0f
                                                           blue: 213.0f / 255.0f
                                                          alpha: 0.75f ];
    
    [ showLocationButton setTitle: @"Hold to show device location" forState: UIControlStateNormal ];
    [ showLocationButton setTitleColor: [ UIColor whiteColor ] forState: UIControlStateNormal ];

    [ showLocationButton addTarget: self action: @selector(showLocation) forControlEvents: UIControlEventTouchDown ];
    [ showLocationButton addTarget: self action: @selector(hideLocation) forControlEvents: UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel ];
    
    return showLocationButton;
}

/*
 *  Set the property of the map to show the user location.  This invokes GPS and thereby increases the usage of the battery.
 */
- (void)showLocation
{
    
    _mapView.showsUserLocation = YES;
}


- (void)hideLocation
{
    static BOOL  firstUsage = YES;
    
    if ( firstUsage == YES )
    {
        UIAlertView *msg = [ [ UIAlertView alloc] initWithTitle: @"Power Consumption"
                                                        message: @"Holding the button to show your location uses iOS Location Services which drain power at a high rate.\n\nWithout the button held, your actions will still trigger using the energy efficient Bluedot Point SDK."
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil ];
        [ msg show ];
        firstUsage = NO;
    }
    
    _mapView.showsUserLocation = NO;
}


/*
 *  Over-ride the did update user location delegate to move to the location of the user.
 */
- (void)mapView: (MKMapView *)mapView didUpdateUserLocation: (MKUserLocation *)userLocation
{
    MKCoordinateRegion  region;
    MKCoordinateSpan  span;
    CLLocationCoordinate2D  location;

    //  Create a span for the visibility of the map
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;

    location.latitude = userLocation.coordinate.latitude;
    location.longitude = userLocation.coordinate.longitude;
    
    region.span = span;
    region.center = location;
    
    [ mapView setRegion: region animated: YES ];
}

@end
