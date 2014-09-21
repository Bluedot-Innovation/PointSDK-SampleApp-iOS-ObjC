//
//  BDLocationChecklistViewController.h
//  BDPointSampleApp
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDZoneInfo;
@class BDFence;

@interface BDZoneChecklistViewController : UIViewController

@property (nonatomic) NSSet* zones;

- (void)didCheckIntoFence:(BDFence*)fence
                   inZone:(BDZoneInfo*)zone;

@end
