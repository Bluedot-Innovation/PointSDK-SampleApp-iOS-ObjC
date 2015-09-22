//
//  BDAppDelegate.m
//  BDPoint
//
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <BDPointSDK.h>

#import "EXAppDelegate.h"

#import "EXZoneMapViewController.h"
#import "EXZoneChecklistViewController.h"
#import "EXAuthenticationViewController.h"
#import "EXNotificationStrings.h"


/*
 *  Anonymous category for local properties.
 */
@interface EXAppDelegate() <BDPointDelegate, UITabBarControllerDelegate, BDPRestartAlertDelegate>

@property (nonatomic) EXZoneChecklistViewController  *zoneChecklistViewController;
@property (nonatomic) EXZoneMapViewController        *zoneMapViewController;
@property (nonatomic) EXAuthenticationViewController *authenticationViewController;
@property (nonatomic) UITabBarController             *tabBarController;

@property (nonatomic) NSArray  *viewControllersNotRequiringZoneInfo;
@property (nonatomic) NSArray  *viewControllersRequiringZoneInfo;

@property (nonatomic) UIAlertView  *userInterventionForBluetoothDialog;
@property (nonatomic) UIAlertView  *userInterventionForLocationServicesDialog;

@property (nonatomic) NSDateFormatter  *dateFormatter;

@end


@implementation EXAppDelegate

- (BOOL)application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
    BDLocationManager  *locationManager = [ BDLocationManager instance ];
    
    //  Assign the delegates to this class
    locationManager.locationDelegate = self;
    locationManager.sessionDelegate = self;

    [ self initializeUserInterface ];

    return YES;
}


- (BOOL)application: (UIApplication *)application
            openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation
{
    NSString  *parameterString = [ url query ];
    NSDictionary  *parameters = [ self parseURLParameters: parameterString ];

    NSString  *username = parameters[ BDPointUsernameKey ];
    NSString  *apiKey = parameters[ BDPointAPIKeyKey ];
    NSString  *packageName = parameters[ BDPointPackageNameKey ];

    BOOL isURLValid = ( username && apiKey && packageName );

    if ( isURLValid == YES )
    {
        NSString  *endpointURLString = parameters[ BDPointEndpointKey ];
        NSURL  *customEndpointURL = [ [ NSURL alloc ] initWithString: endpointURLString ];

        [ _authenticationViewController didReceiveRegistrationWithUsername: username
                                                                    apiKey: apiKey
                                                            andPackageName: packageName
                                                                    andURL: customEndpointURL ];
    }

    return isURLValid;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // This method implementation must be present in AppDelegate
    // when integrating Bluedot Point SDK v1.x, even if it is empty.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // This method implementation must be present in AppDelegate
    // when integrating Bluedot Point SDK v1.x, even if it is empty.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)applicationSignificantTimeChange:(UIApplication *)application
{
    // This method implementation must be present in AppDelegate
    // when integrating Bluedot Point SDK v1.x, even if it is empty.
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // For iOS9 (currently Beta) this method implementation must be present in AppDelegate
    // when integrating Bluedot Point SDK v1.x, even if it is empty.
}

- (NSDictionary *)parseURLParameters: (NSString *)parameters
{
    NSMutableDictionary  *parameterDictionary = [ NSMutableDictionary new ];
    NSScanner  *scanner = [ NSScanner scannerWithString: parameters ];

    NSCharacterSet  *controlCharacters = [ NSCharacterSet characterSetWithCharactersInString: @"&=" ];

    scanner.charactersToBeSkipped = controlCharacters;

    NSString  *paramName;
    NSString  *paramValue;

    while( [ scanner isAtEnd ] == NO )
    {
        if ( [ scanner scanUpToCharactersFromSet: controlCharacters intoString: &paramName ] == NO )
        {
            break;
        }

        [ scanner setScanLocation: scanner.scanLocation + 1 ];

        if ( [ scanner scanUpToCharactersFromSet: controlCharacters intoString: &paramValue ] == NO )
        {
            break;
        }

        parameterDictionary[ paramName ] = [ paramValue urlDecode ];
    }

    return [ NSDictionary dictionaryWithDictionary: parameterDictionary ];
}


- (void)initializeUserInterface
{
    
    //  Setup a generic date formatter
    _dateFormatter = [ NSDateFormatter new ];
    [ _dateFormatter setDateFormat: @"dd-MMM-yyyy HH:mm" ];

    //  Create the tab bar controller
    _tabBarController = [ UITabBarController new ];
    _tabBarController.delegate = self;
    
    //  Create the window
    self.window = [ [ UIWindow alloc ] initWithFrame: UIScreen.mainScreen.bounds ];
    self.window.backgroundColor = UIColor.whiteColor;
    float  viewHeight = UIScreen.mainScreen.bounds.size.height - _tabBarController.tabBar.frame.size.height;

    _authenticationViewController = [ EXAuthenticationViewController new ];
    _zoneMapViewController        = [ [ EXZoneMapViewController alloc ] initWithHeight: viewHeight ];
    _zoneChecklistViewController  = [ EXZoneChecklistViewController new ];

    _authenticationViewController.tabBarItem.image = [ UIImage imageNamed: @"Authenticate" ];
    _zoneMapViewController.tabBarItem.image = [ UIImage imageNamed: @"Map" ];
    _zoneChecklistViewController.tabBarItem.image = [ UIImage imageNamed: @"Checklist" ];

    _viewControllersNotRequiringZoneInfo = @[ _authenticationViewController ];
    _viewControllersRequiringZoneInfo = @[ _zoneMapViewController, _zoneChecklistViewController ];
    [ _tabBarController setViewControllers: _viewControllersNotRequiringZoneInfo ];

    [ self startObservingShowFencesOnMapNotifications ];

    [ self.window setRootViewController: _tabBarController ];
    [ self.window addSubview: _tabBarController.view ];

    [ self.window makeKeyAndVisible ];
}


/**
 * Switches tab-bar controller to the Map view, whenever a EXShowFencesOnMap notification is received.
 */
-(void)startObservingShowFencesOnMapNotifications
{
    void ( ^showZonesNotificationHandler )(NSNotification *) = ^( NSNotification *showFencesNotification )
    {
        NSAssert( BDLocationManager.instance.authenticationState == BDAuthenticationStateAuthenticated, NSInternalInconsistencyException );

        [ _tabBarController setSelectedViewController: _zoneMapViewController ];
    };

    [ NSNotificationCenter.defaultCenter addObserverForName: EXShowFencesOnMapNotification
                                                     object: nil
                                                      queue: NSOperationQueue.mainQueue
                                                 usingBlock: showZonesNotificationHandler ];
}


#pragma mark BDPointDelegate implementation begin

- (void)willAuthenticateWithUsername: (NSString *)username
                              apiKey: (NSString *)apiKey
                         packageName: (NSString *)packageName
{
    NSLog( @"Authenticating with Point service" );
}


- (void)authenticationWasSuccessful
{
    
    NSLog( @"Authenticated successfully with Point service" );
}


- (void)authenticationWasDeniedWithReason: (NSString *)reason
{
    NSLog( @"Authentication with Point service denied, with reason: %@", reason );

    UIAlertView* alertView = [ [ UIAlertView alloc ] initWithTitle: @"Authentication Denied"
                                                           message: reason
                                                          delegate: nil
                                                 cancelButtonTitle: @"OK"
                                                 otherButtonTitles: nil ];

    [ alertView show ];
}


- (void)authenticationFailedWithError: (NSError *)error
{
    NSLog( @"Authentication with Point service failed, with reason: %@", error.localizedDescription );

    NSString  *title;
    NSString  *message;

    //  BDResponseError will be more conveniently exposed in the next version
    BOOL isConnectionError = ( error.userInfo[ EXResponseError ] == NSURLErrorDomain );
    
    if ( isConnectionError == YES )
    {
        title = @"No data connection?";
        message = @"Sorry, but there was a problem connecting to Bluedot servers.\n"
                  "Please check you have a data connection, and that flight mode is disabled, and try again.";
    }
    else
    {
        title = @"Authentication Failed";
        message = error.localizedDescription;
    }
    
    UIAlertView  *alertView = [ [ UIAlertView alloc ] initWithTitle: title
                                                            message: message
                                                           delegate: nil
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil ];

    [ alertView show ];
}


- (void)didEndSession
{
    [ _tabBarController setViewControllers: _viewControllersNotRequiringZoneInfo animated: NO ];
    NSLog( @"Logged out" );
}

/*
 *  This method is passed the Zone information utilised by the Bluedot SDK.
 */
- (void)didUpdateZoneInfo: (NSSet *)zones
{
    NSLog( @"Point service updated with %lu zones", (unsigned long)zones.count );

    NSArray  *viewControllers;

    if ( zones && zones.count > 0 )
    {
        viewControllers = [ _viewControllersNotRequiringZoneInfo arrayByAddingObjectsFromArray: _viewControllersRequiringZoneInfo ];
    }
    else
    {
        viewControllers = _viewControllersNotRequiringZoneInfo;
    }

    //  Enable the view controllers when zone information has been received
    [ _tabBarController setViewControllers: viewControllers
                                  animated: YES ];

    //  Assign the zone information to the Checklist and Map for display
    _zoneChecklistViewController.zones = zones;
    _zoneMapViewController.zones       = zones;
}


/*
 *  A fence with a Custom Action has been checked into; display an alert to notify the user.
 */
- (void)didCheckIntoFence: (BDFenceInfo *)fence
                   inZone: (BDZoneInfo *)zone
             atCoordinate: (BDLocationCoordinate2D)coordinate
                   onDate: (NSDate *)date
{

    NSString *message = [ NSString stringWithFormat: @"You have checked into fence '%@' in zone '%@', at %@",
                         fence.name, zone.name, [ _dateFormatter stringFromDate: date ] ];

    UIAlertView  *alertView = [ [ UIAlertView alloc ] initWithTitle: @"Application notification"
                                                            message: message
                                                           delegate: nil
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil ];
    [ alertView show ];

    //  Update the status of a fence in the Map
    [ _zoneMapViewController didCheckIntoFence: fence ];

    //  Update the status of a fence in the Checklist
    [ _zoneChecklistViewController didCheckIntoFence: fence
                                              inZone: zone ];
}


/*
 *  A beacon with a Custom Action has been checked into; display an alert to notify the user.
 */
- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon
                    inZone: (BDZoneInfo *)zoneInfo
             withProximity: (CLProximity)proximity
                    onDate: (NSDate *)date
{
    NSString *proximityString;

    switch(proximity)
    {
        default:
        case CLProximityUnknown:   proximityString = @"Unknown";   break;
        case CLProximityImmediate: proximityString = @"Immediate"; break;
        case CLProximityNear:      proximityString = @"Near";      break;
        case CLProximityFar:       proximityString = @"Far";       break;
    }

    NSString *message = [ NSString stringWithFormat: @"You have checked into beacon '%@' in zone '%@' with proximity %@ at %@",
                         beacon.name, zoneInfo.name, proximityString, [ _dateFormatter stringFromDate: date ] ];

    UIAlertView  *alertView = [ [ UIAlertView alloc ] initWithTitle: @"Application notification"
                                                            message: message
                                                           delegate: nil
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil ];
    [ alertView show ];

    //  Update the state of a beacon on the Map
    [ _zoneMapViewController didCheckIntoBeacon: beacon ];

    //  Update the state of a beacon on the Checklist
    [ _zoneChecklistViewController didCheckIntoBeacon: beacon
                                               inZone: zoneInfo ];
}

/*
 *  This method is part of the Bluedot location delegate and is called when Bluetooth is required by the SDK but is not enabled
 *  on the device; requiring user intervention.
 */
- (void)didStartRequiringUserInterventionForBluetooth
{
    if ( _userInterventionForBluetoothDialog == nil )
    {
        NSString  *title = @"Bluetooth Required";
        NSString  *message = @"There are nearby Beacons which cannot be detected because Bluetooth is disabled.  Re-enable Bluetooth to restore full functionality.";
        
        _userInterventionForBluetoothDialog = [ [ UIAlertView alloc ] initWithTitle: title
                                                                            message: message
                                                                           delegate: nil
                                                                  cancelButtonTitle: @"Dismiss"
                                                                  otherButtonTitles: nil ];
    }
    
    [ _userInterventionForBluetoothDialog show ];
}

/*
 *  This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously been
 *  required to enable Bluetooth and either user intervention has enabled Bluetooth or the Bluetooth service is no longer required.
 */
- (void)didStopRequiringUserInterventionForBluetooth
{
    [ _userInterventionForBluetoothDialog dismissWithClickedButtonIndex: 0 animated: YES ];
}

/*
 *  This method is part of the Bluedot location delegate and is called when Location Services are not enabled
 *  on the device; requiring user intervention.
 */
- (void)didStartRequiringUserInterventionForLocationServices
{
    if ( _userInterventionForLocationServicesDialog == nil )
    {
        NSString  *appName = [ NSBundle.mainBundle objectForInfoDictionaryKey: @"CFBundleDisplayName" ];
        NSString  *title = @"Location Services Required";
        NSString  *message = [ NSString stringWithFormat: @"This App requires Location Services which are currently disabled.  To restore Location Services, go to :\nSettings → Privacy →\nLocation Settings →\n%@ ✓", appName ];
        
        _userInterventionForLocationServicesDialog = [ [ UIAlertView alloc ] initWithTitle: title
                                                                                   message: message
                                                                                  delegate: nil
                                                                         cancelButtonTitle: nil
                                                                         otherButtonTitles: nil ];
    }
    
    [ _userInterventionForLocationServicesDialog show ];
}

/*
 *  This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously been
 *  required to enable Location Services and either Location Services has been enabled or the user is no longer within an
 *  authenticated session, thereby no longer requiring Location Services.
 */
- (void)didStopRequiringUserInterventionForLocationServices
{
    [ _userInterventionForLocationServicesDialog dismissWithClickedButtonIndex: 0 animated: YES ];
}

#pragma mark BDPointDelegate implementation end


#pragma mark App Restart delegate start

- (NSString *)restartAlertTitle
{
    return( @"Restart BDPoint App by touching this message" );
}

#pragma mark App Restart delegate end



#pragma mark UITabBarControllerDelegate implementation begin

- (BOOL)tabBarController: (UITabBarController *)tabBarController shouldSelectViewController: (UIViewController *)viewController
{
    BOOL isDoubleTapOnMap = ( viewController == _zoneMapViewController ) && ( viewController == tabBarController.selectedViewController );

    
    if ( isDoubleTapOnMap == YES )
    {
        [ _zoneMapViewController zoomToFitZones ];
    }

    return YES;
}

#pragma mark UITabBarControllerDelegate implementation end

@end
