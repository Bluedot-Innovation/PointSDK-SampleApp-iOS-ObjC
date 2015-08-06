//
//  BDBeaconOverlayRenderer.h
//  BDPoint
//
//  Created by Chris Hatton on 5/08/2015.
//  Copyright (c) 2015 Bluedot. All rights reserved.
//

#import <MapKit/MapKit.h>

@class BDBeacon;

@interface BDBeaconOverlayRenderer : MKOverlayRenderer

-(instancetype)initWithBeacon:(BDBeacon*)beacon;

@property (nonatomic) UIColor *rangeColor;

@end
