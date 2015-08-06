//
//  BDBeaconOverlayRenderer.m
//  BDPoint
//
//  Created by Chris Hatton on 5/08/2015.
//  Copyright (c) 2015 Bluedot. All rights reserved.
//

#import "BDBeaconOverlayRenderer.h"
#import "BDBeacon.h"
#import "BDPoint.h"
#import "BDGeospatialUnits.h"

@interface BDBeaconOverlayRenderer ()

@property (nonatomic) BDBeacon *beacon;

@end


@implementation BDBeaconOverlayRenderer
{
    UIColor *_rangeColor;
}

- (instancetype)initWithBeacon:(BDBeacon*)beacon
{
    self = [super init];
    if( self )
    {
        _beacon = beacon;
        _rangeColor = [UIColor blueColor];
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{
    UIImage *beaconIcon = [ UIImage imageNamed: @"BeaconIcon" ];
    
    BDPoint *beaconPoint = _beacon.location.point;
    CLLocationCoordinate2D beaconCoordinate = CLLocationCoordinate2DMake( beaconPoint.latitude, beaconPoint.longitude );
    
    MKMapPoint beaconMapPoint = MKMapPointForCoordinate( beaconCoordinate );
    
    CGPoint beaconScreenPoint = [ self pointForMapPoint: beaconMapPoint ];
    
    CGFloat
        beaconIconScale   = 2.0,
        beaconIconWidth   = ( beaconIcon.size.width  / zoomScale ) * beaconIconScale,
        beaconIconHeight  = ( beaconIcon.size.height / zoomScale ) * beaconIconScale,
        beaconIconCenterX = beaconScreenPoint.x,
        beaconIconCenterY = beaconScreenPoint.y,
        beaconIconOffsetX = -( beaconIconWidth  / 2.0 ),
        beaconIconOffsetY = -( beaconIconHeight / 2.0 );
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceCMYK();
    
    CGFloat rangeColorAlpha = 0.5f;
    
    UIColor
        *rangeGradientColorStart = [ _rangeColor colorWithAlphaComponent: rangeColorAlpha ],
        *rangeGradientColorEnd   = [ _rangeColor colorWithAlphaComponent: 0 ];
    
    NSArray *gradientColors = @[ (id)rangeGradientColorStart.CGColor, (id)rangeGradientColorEnd.CGColor ];
    
    CGGradientRef rangeGradient = CGGradientCreateWithColors(rgbColorSpace, (CFArrayRef)gradientColors, nil );
    
    double pointsPerMeter = MKMapPointsPerMeterAtLatitude( beaconCoordinate.latitude );
    
    CGFloat pointsForRange = _beacon.range * pointsPerMeter;
    
    CGPoint beaconIconCenterPoint = CGPointMake( beaconIconCenterX, beaconIconCenterY );
    
    CGContextDrawRadialGradient(context, rangeGradient, beaconIconCenterPoint, 0, beaconIconCenterPoint, pointsForRange, 0);
    
    CGRect beaconIconRect = CGRectMake( beaconIconCenterX + beaconIconOffsetX, beaconIconCenterY + beaconIconOffsetY, beaconIconWidth, beaconIconHeight );
    
    CGContextDrawImage( context, beaconIconRect, beaconIcon.CGImage );
    
    CGGradientRelease( rangeGradient );
    CGColorSpaceRelease( rgbColorSpace );
}

- (UIColor*)rangeColor
{
    return _rangeColor;
}

- (void)setRangeColor:(UIColor *)rangeColor
{
    _rangeColor = rangeColor;
    
    [ self setNeedsDisplay ];
}

@end
