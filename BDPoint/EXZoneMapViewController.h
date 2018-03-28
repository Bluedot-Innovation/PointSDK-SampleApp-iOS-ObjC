//
//  Created by Bluedot Innovation
//  Copyright (c) 2016 Bluedot Innovation. All rights reserved.
//
//  View Controller to display all the fences and user location in the map view.
//

#import <UIKit/UIKit.h>
@import BDPointSDK;


@interface EXZoneMapViewController : UIViewController

//  Declare the available properties
@property (nonatomic) NSSet  *zones;

//  Declare the available methods
- (id)initWithHeight: (float)height;

- (void)didCheckIntoFence: (BDFenceInfo *)fence;
- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon;

- (void)zoomToFitZones;

@end
