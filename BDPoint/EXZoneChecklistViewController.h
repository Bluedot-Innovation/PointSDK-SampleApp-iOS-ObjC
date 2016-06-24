//
//  Created by Bluedot Innovation
//  Copyright (c) 2016 Bluedot Innovation. All rights reserved.
//
//  View Controller to list all the zones and spatial objects.
//

#import <UIKit/UIKit.h>

@class BDZoneInfo;
@class BDFenceInfo;
@class BDBeaconInfo;


@interface EXZoneChecklistViewController : UIViewController

//  Declare the available properties for this class
@property (nonatomic) NSSet  *zones;

//  Declare the available methods
- (void)didCheckIntoFence: (BDFenceInfo *)fence
                   inZone: (BDZoneInfo *)zone;

- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon
                    inZone: (BDZoneInfo *)zone;

@end
