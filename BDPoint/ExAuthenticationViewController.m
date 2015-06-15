//
// Created by Chris Hatton on 12/03/2014.
// Copyright (c) 2014 Chris Hatton. All rights reserved.
//

#import <BDPointSDK.h>

#import "EXAuthenticationViewController.h"
#import "EXNotificationStrings.h"
#import "BDStyles.h"


//  Declare constants
static const float  cornerRadius = 5.0f;
static const float  borderWidth = 1.5f;


typedef enum
{
    authenticationViewControllerAltActionNone,
    authenticationViewControllerAltActionRegister,
    authenticationViewControllerAltActionIntegrate
}
EXAuthenticationViewControllerAltAction;


/*
 *  Anonymous category for local properties.
 */
@interface EXAuthenticationViewController () <UITextFieldDelegate>

@property (nonatomic) id  authenticationStateObservation;
@property (nonatomic, assign) EXAuthenticationViewControllerAltAction  alternateAction;
@property (nonatomic, assign) BOOL  firstAppearance;
@property (nonatomic) NSURL  *customEndpointURL;

@end


@implementation EXAuthenticationViewController

- (id)init
{

    if ( ( self = [super init] ) != nil )
    {
        _firstAppearance = YES;
        [ self createDefaultsOnFirstRun ];
    }
    
    return self;
}


/**
 *
 * To use this Bluedot Point SDK example Application, you should first visit http://bluedot.com.au
 *
 * Follow the sign-up instructions to create an account.  Use the web interface to define Zones, Fences,
 * Actions and Conditions. Then, enter the provided account credentials below to compile an example App which will
 * respond to the rules you have set.
 */
- (void)createDefaultsOnFirstRun
{
    NSUserDefaults  *defaults = [ NSUserDefaults standardUserDefaults ];
    BOOL isFirstRun = ( [ defaults objectForKey: BDPointUsernameKey ] == nil );

    if ( isFirstRun == YES )
    {
        [ defaults setObject: @"" forKey: BDPointUsernameKey    ];
        [ defaults setObject: @"" forKey: BDPointAPIKeyKey      ];
        [ defaults setObject: @"" forKey: BDPointPackageNameKey ];
    }
}


/*
 *  After view has loaded.
 */
- (void)viewDidLoad
{
    
    [ super viewDidLoad ];

    //  Set the view properties
    self.title = @"Authentication";
    [ self reset ];

    [ self applyControlStyles ];
}


/*
 *  Immediately prior to the view appearing.
 */
- (void)viewWillAppear: (BOOL)animated
{
    
    [ super viewWillAppear: animated ];    
    [ self startObservingAuthenticationState ];
    
    if ( _firstAppearance == YES )
    {
        _firstAppearance = NO;
        [ self animateInterfacePanelAppearance ];
    }
}


/*
 *  Fade the panel in using animation of the alpha value.
 */
- (void)animateInterfacePanelAppearance
{
    CGFloat  initialZoomFactor = 0.9f;
    
    _interfacePanel.transform = CGAffineTransformMakeScale( initialZoomFactor, initialZoomFactor );
    _interfacePanel.alpha = 0.0f;
    
    dispatch_block_t interfacePanelZoomAnimation = ^
    {
        _interfacePanel.transform = CGAffineTransformIdentity;
        _interfacePanel.alpha = 1.0f;
    };
    
    [ UIView animateWithDuration: 0.4f
                      animations: interfacePanelZoomAnimation ];
}


/*
 *  Immediately prior to the view disappearing.
 */
- (void)viewWillDisappear: (BOOL)animated
{
    [ super viewWillDisappear: animated ];
    [ self stopObservingAuthenticationState ];
}


/*
 *  Set the control styles for the fields.
 */
- (void)applyControlStyles
{
    
    [ _alternateActionButton setTitleColor: _loginButton.backgroundColor forState: UIControlStateNormal ];

    [ self styleTextField: _apiKeyTextField ];
    [ self styleTextField: _packageTextField ];
    [ self styleTextField: _usernameTextField ];
}

- (void)styleTextField: (UITextField *)textField
{
    
    textField.layer.borderColor = BDGrayColor.CGColor;
    textField.layer.borderWidth  = borderWidth;
    textField.layer.cornerRadius = cornerRadius;
}


/*
 *  A registration has been completed.
 */
- (void)didReceiveRegistrationWithUsername: (NSString *)username
                                    apiKey: (NSString *)apiKey
                            andPackageName: (NSString *)packageName
                                    andURL: (NSURL *)endpointURL
{
    _usernameTextField.text = username;
    _packageTextField.text = packageName;
    _apiKeyTextField.text = apiKey;
    
    _customEndpointURL = endpointURL;
    
    NSString  *title   = @"Details auto-filled";
    NSString  *message = @"Your Application's details have been automatically entered and remembered.\n\n"
                         "When you have created one or more Zones in the Bluedot Point web interface, touch the 'Log In' button below, to enter your Application scenario.";

    UIAlertView  *alertView = [ [ UIAlertView alloc ] initWithTitle: title
                                                            message: message
                                                           delegate: nil
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil ];

    [ alertView show ];
}


#pragma mark IBAction handlers begin

- (IBAction)loginButtonTouchUpInside
{
    BDLocationManager  *locationManager = BDLocationManager.instance;

    //  Determine the authentication state
    switch( locationManager.authenticationState )
    {
        case BDAuthenticationStateNotAuthenticated:
            [ self authenticate ];
            break;

        case BDAuthenticationStateAuthenticated:
            [ locationManager logOut ];
            break;

        default:
            break;
    }
}


/*
 *  Only log out of the location manager if the app is authenticated.
 */
- (IBAction)resetButtonTouchUpInside
{
    BDLocationManager  *locationManager = BDLocationManager.instance;

    if ( locationManager.authenticationState == BDAuthenticationStateAuthenticated )
    {
        [ locationManager logOut ];
    }

    [ self reset ];
}

#pragma mark IBAction handlers end


- (void)reset
{
    NSUserDefaults  *defaults = [ NSUserDefaults standardUserDefaults ];

    self.usernameTextField.text = [ defaults objectForKey: BDPointUsernameKey   ] ?: @"";
    self.apiKeyTextField.text   = [ defaults objectForKey: BDPointAPIKeyKey     ] ?: @"";
    self.packageTextField.text  = [ defaults objectForKey: BDPointPackageNameKey] ?: @"";

    NSString  *encodedEndpointURLString = [ defaults objectForKey: BDPointEndpointKey ];
    NSString  *endpointURLString        = [ encodedEndpointURLString urlDecode ];

    _customEndpointURL = endpointURLString ? [ [ NSURL alloc ] initWithString: endpointURLString ] : nil;
}


-(void)setInputFieldsEnabled:(BOOL)enabled
{

    self.usernameTextField.enabled = enabled;
    self.apiKeyTextField.enabled   = enabled;
    self.packageTextField.enabled  = enabled;
}


-(void)authenticate
{
    [ self.view endEditing: YES ];

    NSString  *apiKey = _apiKeyTextField.text;
    NSString  *packageName = _packageTextField.text;
    NSString  *username = _usernameTextField.text;

    NSUserDefaults *defaults = [ NSUserDefaults standardUserDefaults ];

    [ defaults setValue: apiKey      forKey: BDPointAPIKeyKey ];
    [ defaults setValue: packageName forKey: BDPointPackageNameKey ];
    [ defaults setValue: username    forKey: BDPointUsernameKey ];
    
    BDLocationManager  *locationManager = BDLocationManager.instance;

    /*
     *  The default method to connect to the Bluedot Innovations back-end is utilising the method below.
     *
     *  Should a specific Bluedot back-end be required, then a custom URL can be utilised to authenticate the app.
     */
    if ( _customEndpointURL == nil )
    {
        [ locationManager authenticateWithApiKey: apiKey
                                     packageName: packageName
                                        username: username ];
    }
    else
    {
        NSAssert( [ _customEndpointURL isKindOfClass:NSURL.class ], NSInternalInconsistencyException );

        NSString  *customEndpointURLString = [ _customEndpointURL absoluteString ];
        [ defaults setValue: customEndpointURLString forKey: BDPointEndpointKey ];

        [ locationManager authenticateWithApiKey: apiKey
                                     packageName: packageName
                                        username: username
                                     endpointURL: _customEndpointURL ];
    }
}


#pragma mark Authentication state observation begin

/*
 *  Start observing the authentication state of the Bluepoint SDK with the back-end.
 */
- (void)startObservingAuthenticationState
{
    NSAssert( _authenticationStateObservation == nil, NSInternalInconsistencyException );

    BDLocationManager  *locationManager = BDLocationManager.instance;

    /*
     *  Create a block to handle authentication changes.
     */
    BDKVOValueChangeHandler authenticationStateChangeHandler = ^( id source, NSString *keyPath, NSNumber *oldValue, NSNumber *newValue )
    {
        BDAuthenticationState state = (BDAuthenticationState)[ newValue unsignedIntegerValue ];

        BOOL  resetButtonEnabled;
        BOOL  loginButtonEnabled;
        BOOL  inputFieldsEnabled;

        NSString  *buttonTitle;
        NSString  *newPromptTitle;
        NSString  *alternateActionTitle;

        switch( state )
        {
            case BDAuthenticationStateNotAuthenticated:
                buttonTitle        = @"Log in";
                resetButtonEnabled = YES;
                loginButtonEnabled = YES;
                inputFieldsEnabled = YES;
                newPromptTitle     = @"Enter your account details";
                _alternateAction   = authenticationViewControllerAltActionRegister;
                break;

            case BDAuthenticationStateAuthenticating:
                buttonTitle        = @"Logging in...";
                resetButtonEnabled = NO;
                loginButtonEnabled = NO;
                inputFieldsEnabled = NO;
                newPromptTitle     = nil;
                _alternateAction   = authenticationViewControllerAltActionNone;
                break;

            case BDAuthenticationStateAuthenticated:
                buttonTitle        = @"Log out";
                resetButtonEnabled = NO;
                loginButtonEnabled = YES;
                inputFieldsEnabled = NO;
                newPromptTitle     = @"You are logged in as";
                _alternateAction   = authenticationViewControllerAltActionIntegrate;
                break;

            default:
                @throw [ NSException exceptionWithName: NSInternalInconsistencyException
                                                reason: @"Unknown authentication authenticationState"
                                              userInfo: nil ];
        }

        switch( _alternateAction )
        {
            case authenticationViewControllerAltActionNone:
                alternateActionTitle = @"";
                break;

            case authenticationViewControllerAltActionRegister:
                alternateActionTitle = @"Don't have an account?";
                break;

            case authenticationViewControllerAltActionIntegrate:
                alternateActionTitle = @"About the Bluedot Point SDK";
                break;
        }

        self.resetButton.enabled         = resetButtonEnabled;
        self.resetButton.backgroundColor = resetButtonEnabled ? BDButtonEnabledColor : BDButtonDisabledColor;

        self.loginButton.enabled         = loginButtonEnabled;
        self.loginButton.backgroundColor = loginButtonEnabled ? BDButtonEnabledColor : BDButtonDisabledColor;

        self.inputFieldsEnabled = inputFieldsEnabled;

        [ self.loginButton           setTitle: buttonTitle          forState: UIControlStateNormal ];
        [ self.alternateActionButton setTitle: alternateActionTitle forState: UIControlStateNormal ];

        /*
         *  If a new prompt title has been assigned, then assign it to the label.
         */
        if ( newPromptTitle != nil )
        {
            self.promptLabel.text = newPromptTitle;
        }
    };

    /*
     *  Add an observation on the authentication state of the Bluedot SDK.  A token is returned for use in
     *  stopping the observation.
     */
    _authenticationStateObservation = [ locationManager addValueObserverBlock: authenticationStateChangeHandler
                                                                   forKeyPath: EXAuthenticationState
                                                                      initial: YES ];

    NSAssert( _authenticationStateObservation, NSInternalInconsistencyException );
}


/*
 *  Stop observing the authentication state of the Bluepoint SDK with the back-end using the token provided on starting.
 */
- (void)stopObservingAuthenticationState
{
    NSAssert( _authenticationStateObservation, NSInternalInconsistencyException );

    /*
     *  Stop observing and reset the token to nil.
     */
    [ BDLocationManager.instance removeBlockKVObservation: _authenticationStateObservation ];
    _authenticationStateObservation = nil;
}

#pragma mark Authentication state observation end


/*
 *  Ensure the observation is stopped prior to exiting.
 */
-(void)dealloc
{
    
    if ( _authenticationStateObservation != nil )
    {
        [ self stopObservingAuthenticationState ];
    }
}


#pragma mark UITextFieldDelegate implementation begin

- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
    
    [ textField resignFirstResponder ];

    return YES;
}

#pragma mark UITextFieldDelegate implementation end

@end