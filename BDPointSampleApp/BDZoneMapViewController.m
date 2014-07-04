//
//  BDZoneMapViewController.m
//  BDPointSampleApp
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import "BDZoneMapViewController.h"
#import "MKMapView+BDPoint.h"
#import "BDFocusFencesNotification.h"

#define BDFenceColorDefault       UIColor.grayColor
#define BDFenceColorCheckedIn     UIColor.cyanColor
#define BDFenceColorCheckedInLast UIColor.greenColor

#define BDFenceMapInset 10.0f

@interface BDZoneMapViewController () <MKMapViewDelegate>

@property (nonatomic, readonly) MKMapView* mapView;
@property (nonatomic) BDFenceOverlayRendererFactory*fenceRendererFactory;

@property (nonatomic) NSMapTable* fenceRendererCache;
@property (nonatomic) NSMapTable* fenceCheckInStatuses;
@property (nonatomic) BDFence*    lastCheckedInFence;

@property (nonatomic) UIEdgeInsets fenceMapInsets;

@end


@implementation BDZoneMapViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.title = @"Map";

        _fenceCheckInStatuses = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality
                                                          valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality
                                                              capacity:8];

        _fenceRendererFactory = [[BDFenceOverlayRendererFactory alloc] initWithFillColor:UIColor.cyanColor
                                                                             strokeColor:UIColor.cyanColor
                                                                             strokeWidth:2.0f
                                                                                   alpha:0.6f];
        _fenceRendererCache   = [NSMapTable weakToStrongObjectsMapTable];

        _fenceMapInsets = UIEdgeInsetsMake(BDFenceMapInset, BDFenceMapInset, BDFenceMapInset, BDFenceMapInset);

        void (^showFencesNotificationHandler)(NSNotification*) = ^(NSNotification *showFencesNotification)
        {
            NSSet* fences = showFencesNotification.object;
            [self.mapView setRegionToFitOverlays:fences
                                     withPadding:_fenceMapInsets
                                        animated:YES];
        };

        [NSNotificationCenter.defaultCenter addObserverForName:BDShowFencesOnMapNotification
                                                        object:NULL
                                                         queue:[NSOperationQueue mainQueue]
                                                    usingBlock:showFencesNotificationHandler];
    }
    return self;
}

-(void)loadView
{
    MKMapView* mapView = [MKMapView new];

    mapView.showsUserLocation = YES;
    mapView.delegate = self;

    self.view = mapView;
}

-(MKMapView*)mapView
{
    return (MKMapView*)self.view;
}

-(void)setZones:(NSSet *)zones
{
    for(BDFence* fence in _fenceCheckInStatuses.keyEnumerator)
        [self.mapView removeOverlay:fence];

    [_fenceCheckInStatuses removeAllObjects];

    for(BDZoneInfo* zone in zones)
        for (BDFence *fence in zone.fences)
            [_fenceCheckInStatuses setObject:@(NO) forKey:fence];

    [self.mapView addOverlays:_fenceCheckInStatuses.keyEnumerator.allObjects];

    [self.mapView setRegionToFitAllOverlaysWithPadding:_fenceMapInsets
                                              animated:YES];
}

- (void)didCheckIntoFence:(BDFence *)fence
{
    [_fenceCheckInStatuses setObject:@(YES) forKey:fence];

    [self refreshFenceAppearance:fence];
}

- (void)zoomToFitZones
{
    [self.mapView setRegionToFitAllOverlaysWithPadding:_fenceMapInsets
                                              animated:YES];
}


#pragma mark MKMapViewDelegate begin

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay
{
    NSAssert([overlay isKindOfClass:BDFence.class], NSInternalInconsistencyException);

    BDFence* fence = (BDFence*)overlay;

    MKOverlayRenderer* renderer = [_fenceRendererCache objectForKey:fence];

    if(!renderer)
    {
        renderer = [_fenceRendererFactory rendererForFence:fence];
        [_fenceRendererCache setObject:renderer forKey:fence];
        
        [self refreshFenceAppearance:fence];
    }

    return renderer;
}

#pragma mark MKMapViewDelegate end


-(BOOL)hasCheckedIntoFence:(BDFence*)fence
{
    _lastCheckedInFence = fence;
    return [(NSNumber*)[_fenceCheckInStatuses objectForKey:fence] boolValue];
}

-(void)refreshFenceAppearance:(BDFence*)fence
{
    MKOverlayPathRenderer *fenceRenderer = (MKOverlayPathRenderer*)[self mapView:self.mapView rendererForOverlay:fence];

    UIColor* fenceColor;

    if(fence==_lastCheckedInFence)
        fenceColor = BDFenceColorCheckedInLast;
    else if([self hasCheckedIntoFence:fence])
        fenceColor = BDFenceColorCheckedIn;
    else
        fenceColor = BDFenceColorDefault;

    fenceRenderer.fillColor   = fenceColor;
    fenceRenderer.strokeColor = fenceColor;
    
    [self.mapView setNeedsDisplay];
}

@end
