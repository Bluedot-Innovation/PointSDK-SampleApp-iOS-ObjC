//
//  BDZoneMapViewController.h
//  BDPoint
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BDPointSDK.h>


@interface EXZoneMapViewController : UIViewController

//  Declare the available properties
@property (nonatomic) NSSet  *zones;

//  Declare the available methods
- (id)initWithHeight: (float)height;

- (void)didCheckIntoSpatialObject: (id <BDPSpatialObject>)spatialObject;
- (void)zoomToFitZones;

@end
