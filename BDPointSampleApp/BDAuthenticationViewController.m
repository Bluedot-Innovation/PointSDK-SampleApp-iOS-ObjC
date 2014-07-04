//
// Created by Chris Hatton on 12/03/2014.
// Copyright (c) 2014 Chris Hatton. All rights reserved.
//

#import "BDAuthenticationViewController.h"
#import "NSObject+BDKVOBlocks.h"
#import "BDDefaultCredentials.h"
#import "BDStyles.h"
#import "NSString+BDURLEncoding.h"
#import <BDPointSDK.h>

#define BDActionURLRegister          @"http://www.bluedot.com.au"
#define BDActionURLIntegrateMoreInfo @"http://www.bluedot.com.au"
#define BDActionURLIntegrateCode     @"https://github.com/Bluedot-Innovation"

typedef enum _BDAuthenticationViewControllerAltAction
{
    BDAuthenticationViewControllerAltActionNone,
    BDAuthenticationViewControllerAltActionRegister,
    BDAuthenticationViewControllerAltActionIntegrate
}
BDAuthenticationViewControllerAltAction;


@interface BDAuthenticationViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic) id authenticationStateObservation;
@property (nonatomic,assign) BDAuthenticationViewControllerAltAction alternateAction;
@property (nonatomic,assign) BOOL firstAppearance;
@property (nonatomic) NSURL* customEndpointURL;

@end


@implementation BDAuthenticationViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        _firstAppearance = YES;

        [self createDefaultsOnFirstRun];
    }
    return self;
}

- (void)createDefaultsOnFirstRun
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL isFirstRun = [defaults objectForKey:BDPointUsernameKey]==NULL;

    if(isFirstRun)
    {
        [defaults setObject:BDPointUsername    forKey:BDPointUsernameKey   ];
        [defaults setObject:BDPointAPIKey      forKey:BDPointAPIKeyKey     ];
        [defaults setObject:BDPointPackageName forKey:BDPointPackageNameKey];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Authentication";

    [self reset];

    [self applyControlStyles];
}

-(void)applyControlStyles
{
    [_alternateActionButton setTitleColor:_loginButton.backgroundColor forState:UIControlStateNormal];

    [self styleTextField:_apiKeyTextField];
    [self styleTextField:_packageTextField];
    [self styleTextField:_usernameTextField];
}

-(void)styleTextField:(UITextField*)textField
{
    textField.layer.borderColor  = BDGrayColor.CGColor;
    textField.layer.borderWidth  = 1.5;
    textField.layer.cornerRadius = 5.0;
}

- (void)didReceiveRegistrationWithUsername:(NSString *)username
                                    apiKey:(NSString *)apiKey
                            andPackageName:(NSString *)packageName
                                    andURL:(NSURL*)endpointURL
{
    _usernameTextField.text = username;
    _packageTextField.text  = packageName;
    _apiKeyTextField.text   = apiKey;
    
    _customEndpointURL = endpointURL;
    
    NSString
        *title   = @"Details Auto-filled",
        *message = @"Your Application's details have been automatically entered into this form and remembered.\n\n"
                    "When you have created one or more Zones in the Bluedot Point web interface, touch the 'Log In' button below, to test their behaviour.";

    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:NULL
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:NULL];

    [alertView show];
}


#pragma mark IBAction handlers begin

- (IBAction)loginButtonTouchUpInside
{
    BDLocationManager* locationManager = BDLocationManager.sharedLocationManager;

    switch(locationManager.authenticationState)
    {
        case BDAuthenticationStateNotAuthenticated:
            [self authenticate];
            break;

        case BDAuthenticationStateAuthenticated:
            [locationManager logOut];
            break;

        default:
        break;
    }
}

- (IBAction)resetButtonTouchUpInside
{
    BDLocationManager* locationManager = BDLocationManager.sharedLocationManager;

    if(locationManager.authenticationState==BDAuthenticationStateAuthenticated)
        [locationManager logOut];

    [self reset];
}

- (IBAction)alternateActionButtonTouchUpInside
{
    NSString
        *title,
        *message,
        *cancelButtonTitle;

    NSArray *acceptButtonTitles;

    switch(_alternateAction)
    {
        default:
        case BDAuthenticationViewControllerAltActionRegister:
            title              = @"See Bluedot Point in action",
            message            = @"Register for a free account, and you can start triggering your own location-based "
                                 "actions within minutes, using this example Application.";
            cancelButtonTitle  = @"No thanks";
            acceptButtonTitles = @[@"Register now"];
            break;

        case BDAuthenticationViewControllerAltActionIntegrate:
            title              = @"Your own location-aware Apps",
            message            = @"Get high-precision, low battery-drain location awareness in your own Apps by "
                                 "integrating the Bluedot Point SDK.";
            cancelButtonTitle  = @"No thanks";
            acceptButtonTitles = @[@"Find out more",@"Show me the code!"];
            break;
    }

    UIAlertView* alternateActionAlert = [[UIAlertView alloc] initWithTitle:title
                                                                   message:message
                                                                  delegate:self
                                                         cancelButtonTitle:cancelButtonTitle
                                                         otherButtonTitles:NULL];

    for(NSString* acceptButtonTitle in acceptButtonTitles)
        [alternateActionAlert addButtonWithTitle:acceptButtonTitle];

    [alternateActionAlert show];
}

#pragma mark IBAction handlers end

-(void)reset
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.usernameTextField.text = [defaults objectForKey:BDPointUsernameKey   ] ?: @"";
    self.apiKeyTextField.text   = [defaults objectForKey:BDPointAPIKeyKey     ] ?: @"";
    self.packageTextField.text  = [defaults objectForKey:BDPointPackageNameKey] ?: @"";
    
    _customEndpointURL          = [[defaults objectForKey:BDPointEndpointKey] urlDecode];
}

-(void)setInputFieldsEnabled:(BOOL)enabled
{
    self.usernameTextField.enabled = enabled;
    self.apiKeyTextField.enabled   = enabled;
    self.packageTextField.enabled  = enabled;
}

-(void)authenticate
{
    [self.view endEditing:YES];

    NSString
        *apiKey      = _apiKeyTextField.text,
        *packageName = _packageTextField.text,
        *username    = _usernameTextField.text;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setValue:apiKey      forKey:BDPointAPIKeyKey];
    [defaults setValue:packageName forKey:BDPointPackageNameKey];
    [defaults setValue:username    forKey:BDPointUsernameKey];
    
    BDLocationManager* locationManager = BDLocationManager.sharedLocationManager;
    
    if(_customEndpointURL)
    {
        NSAssert([_customEndpointURL isKindOfClass:NSURL.class], NSInternalInconsistencyException);

        NSString* customEndpointURLString = [_customEndpointURL absoluteString];
        [defaults setValue:customEndpointURLString forKey:BDPointEndpointKey];
        
        [locationManager authenticateWithApiKey:apiKey
                                    packageName:packageName
                                       username:username
                                    endpointURL:_customEndpointURL];
    }
    else
    {
        [locationManager authenticateWithApiKey:apiKey
                                    packageName:packageName
                                       username:username];
    }
}

#pragma mark Authentication state observation begin

-(void)startObservingAuthenticationState
{
    NSAssert(!_authenticationStateObservation, NSInternalInconsistencyException);

    BDLocationManager* locationManager = BDLocationManager.sharedLocationManager;

    BDKVOValueChangeHandler authenticationStateChangeHandler
            = ^(id source, NSString* keyPath, NSNumber* oldValue, NSNumber* newValue)
    {
        BDAuthenticationState state = (BDAuthenticationState)[newValue unsignedIntegerValue];

        BOOL
            resetButtonEnabled,
            loginButtonEnabled,
            inputFieldsEnabled;

        NSString
            *buttonTitle,
            *newPromptTitle,
            *alternateActionTitle;

        switch(state)
        {
            case BDAuthenticationStateNotAuthenticated:
                buttonTitle        = @"Log in";
                resetButtonEnabled = YES;
                loginButtonEnabled = YES;
                inputFieldsEnabled = YES;
                newPromptTitle     = @"Enter your account details";
                _alternateAction   = BDAuthenticationViewControllerAltActionRegister;
                break;

            case BDAuthenticationStateAuthenticating:
                buttonTitle        = @"Logging in...";
                resetButtonEnabled = NO;
                loginButtonEnabled = NO;
                inputFieldsEnabled = NO;
                newPromptTitle     = NULL;
                _alternateAction   = BDAuthenticationViewControllerAltActionNone;
                break;

            case BDAuthenticationStateAuthenticated:
                buttonTitle        = @"Log out";
                resetButtonEnabled = NO;
                loginButtonEnabled = YES;
                inputFieldsEnabled = NO;
                newPromptTitle     = @"You are logged in as";
                _alternateAction   = BDAuthenticationViewControllerAltActionIntegrate;
                break;

            default: @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                                    reason:@"Unknown authentication authenticationState"
                                                  userInfo:NULL];
        }

        switch(_alternateAction)
        {
            case BDAuthenticationViewControllerAltActionNone:
                alternateActionTitle = @"";
                break;

            case BDAuthenticationViewControllerAltActionRegister:
                alternateActionTitle = @"Don't have an account yet?";
                break;

            case BDAuthenticationViewControllerAltActionIntegrate:
                alternateActionTitle = @"Ready to integrate?";
                break;
        }

        self.resetButton.enabled         = resetButtonEnabled;
        self.resetButton.backgroundColor = resetButtonEnabled ? BDButtonEnabledColor : BDButtonDisabledColor;

        self.loginButton.enabled         = loginButtonEnabled;
        self.loginButton.backgroundColor = loginButtonEnabled ? BDButtonEnabledColor : BDButtonDisabledColor;

        self.inputFieldsEnabled  = inputFieldsEnabled;

        [self.loginButton           setTitle:buttonTitle          forState:UIControlStateNormal];
        [self.alternateActionButton setTitle:alternateActionTitle forState:UIControlStateNormal];

        if(newPromptTitle)
            self.promptLabel.text = newPromptTitle;
    };

    _authenticationStateObservation =
            [locationManager addValueObserverBlock:authenticationStateChangeHandler
                                        forKeyPath:@"authenticationState"
                                           initial:YES];

    NSAssert(_authenticationStateObservation, NSInternalInconsistencyException);
}

-(void)stopObservingAuthenticationState
{
    NSAssert(_authenticationStateObservation, NSInternalInconsistencyException);

    [BDLocationManager.sharedLocationManager removeBlockKVObservation:_authenticationStateObservation];
    _authenticationStateObservation = NULL;
}

#pragma mark Authentication state observation end


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self startObservingAuthenticationState];

    if(_firstAppearance)
    {
        _firstAppearance = NO;
        [self animateInterfacePanelAppearance];
    }
}

- (void)animateInterfacePanelAppearance
{
    CGFloat initialZoomFactor = 0.9f;

    _interfacePanel.transform = CGAffineTransformMakeScale(initialZoomFactor, initialZoomFactor);
    _interfacePanel.alpha     = 0;

    dispatch_block_t interfacePanelZoomAnimation = ^
    {
        _interfacePanel.transform = CGAffineTransformIdentity;
        _interfacePanel.alpha     = 1.0f;
    };

    [UIView animateWithDuration:0.4f
                     animations:interfacePanelZoomAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self stopObservingAuthenticationState];
}

-(void)dealloc
{
    if(_authenticationStateObservation)
        [self stopObservingAuthenticationState];
}


#pragma mark UITextFieldDelegate implementation begin

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

#pragma mark UITextFieldDelegate implementation end


#pragma mark UIAlertViewDelegate implementation begin

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString* actionURLString = NULL;

    switch(_alternateAction)
    {
        case BDAuthenticationViewControllerAltActionNone:
        default:
        break;

        case BDAuthenticationViewControllerAltActionRegister:
        {
            switch(buttonIndex)
            {
                case 0: default: break;
                case 1: actionURLString = BDActionURLRegister; break;
            }
        }

        case BDAuthenticationViewControllerAltActionIntegrate:
        {
            switch(buttonIndex)
            {
                case 0: default:                                        break;
                case 1: actionURLString = BDActionURLIntegrateMoreInfo; break;
                case 2: actionURLString = BDActionURLIntegrateCode;     break;
            }
        }
        break;
    }

    if(actionURLString)
    {
        NSURL *actionURL = [[NSURL alloc] initWithString:actionURLString];

        UIApplication *application = UIApplication.sharedApplication;

        if ([application canOpenURL:actionURL])
            [application openURL:actionURL];
    }
}

#pragma mark UIAlertViewDelegate implementation end

@end