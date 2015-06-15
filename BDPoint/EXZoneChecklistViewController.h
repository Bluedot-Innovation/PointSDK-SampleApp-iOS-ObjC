//
//  BDLocationChecklistViewController.h
//  BDPoint
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDZoneInfo;
@class BDFence;


@interface EXZoneChecklistViewController : UIViewController

//  Declare the available properties for this class
@property (nonatomic) NSSet  *zones;

//  Declare the available methods
- (void)didCheckIntoSpatialObject:(id <BDPSpatialObject>)spatialObject
                           inZone: (BDZoneInfo *)zone;

@end
