//
// Created by Chris Hatton on 12/03/2014.
// Copyright (c) 2014 Chris Hatton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDLocationManager;

//  Declare the constants
static NSString  *BDPointAPIKeyKey      = @"BDPointAPIKey";
static NSString  *BDPointPackageNameKey = @"BDPointPackageName";
static NSString  *BDPointUsernameKey    = @"BDPointUsername";
static NSString  *BDPointEndpointKey    = @"BDPointAPIUrl";


@interface EXAuthenticationViewController : UIViewController

//  Declare the properties available
@property (nonatomic) IBOutlet UILabel  *promptLabel;

@property (nonatomic) IBOutlet UIButton  *loginButton;
@property (nonatomic) IBOutlet UIButton  *resetButton;
@property (nonatomic) IBOutlet UIButton  *alternateActionButton;

@property (nonatomic) IBOutlet UITextField  *apiKeyTextField;
@property (nonatomic) IBOutlet UITextField  *packageTextField;
@property (nonatomic) IBOutlet UITextField  *usernameTextField;

@property (nonatomic) IBOutlet UIView  *interfacePanel;


//  Methods available
- (void)didReceiveRegistrationWithUsername: (NSString *)username
                                    apiKey: (NSString *)apiKey
                            andPackageName: (NSString *)packageName
                                    andURL: (NSURL *)endpointURL;

- (IBAction)loginButtonTouchUpInside;
- (IBAction)resetButtonTouchUpInside;

@end