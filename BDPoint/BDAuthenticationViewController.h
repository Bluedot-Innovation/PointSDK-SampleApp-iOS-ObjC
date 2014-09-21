//
// Created by Chris Hatton on 12/03/2014.
// Copyright (c) 2014 Chris Hatton. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BDPointAPIKeyKey      @"BDPointAPIKey"
#define BDPointPackageNameKey @"BDPointPackageName"
#define BDPointUsernameKey    @"BDPointUsername"
#define BDPointEndpointKey    @"BDPointAPIUrl"

@class BDLocationManager;

@interface BDAuthenticationViewController : UIViewController

-(void)didReceiveRegistrationWithUsername:(NSString*)username
                                   apiKey:(NSString*)apiKey
                           andPackageName:(NSString*)packageName
                                   andURL:(NSURL*)endpointURL;

-(IBAction)loginButtonTouchUpInside;
-(IBAction)resetButtonTouchUpInside;

@property (nonatomic) IBOutlet UILabel
        *promptLabel;

@property (nonatomic) IBOutlet UIButton
        *loginButton,
        *resetButton,
        *alternateActionButton;

@property (nonatomic) IBOutlet UITextField
        *apiKeyTextField,
        *packageTextField,
        *usernameTextField;

@property (nonatomic) IBOutlet UIView
        *interfacePanel;

@end