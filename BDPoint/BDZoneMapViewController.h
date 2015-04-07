//
//  BDZoneMapViewController.h
//  BDPoint
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BDPointSDK/BDPointSDK.h>


@interface BDZoneMapViewController : UIViewController

@property (nonatomic) NSSet* zones;

-(void)didCheckIntoFence:(BDFence*)fence;

-(void)zoomToFitZones;

@end
