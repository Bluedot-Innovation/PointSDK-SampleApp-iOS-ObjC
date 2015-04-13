//
//  BDAppDelegate.m
//  BDPoint
//
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <BDPointSDK.h>

#import "BDAppDelegate.h"

#import "BDZoneMapViewController.h"
#import "BDZoneChecklistViewController.h"
#import "BDAuthenticationViewController.h"
#import "BDFocusFencesNotification.h"

@interface BDAppDelegate() <BDPointDelegate, UITabBarControllerDelegate>

@property (nonatomic) BDZoneChecklistViewController  *zoneChecklistViewController;
@property (nonatomic) BDZoneMapViewController        *zoneMapViewController;
@property (nonatomic) BDAuthenticationViewController *authenticationViewController;
@property (nonatomic) UITabBarController             *tabBarController;

@property (nonatomic) NSArray
    *viewControllersNotRequiringZoneInfo,
    *viewControllersRequiringZoneInfo;

@property (nonatomic) UIAlertView* locationDeniedDialog;

@end


@implementation BDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BDLocationManager* locationManager = [BDLocationManager sharedLocationManager];
    locationManager.locationDelegate = self;
    locationManager.authenticationDelegate = self;

    [self initializeUserInterface];

    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    NSString*     parameterString = [url query];
    NSDictionary* parameters      = [self parseURLParameters:parameterString];

    NSString
        *username    = parameters[BDPointUsernameKey],
        *apiKey      = parameters[BDPointAPIKeyKey],
        *packageName = parameters[BDPointPackageNameKey];

    BOOL isURLValid = (username && apiKey && packageName);

    if(isURLValid)
    {
        NSString* endpointURLString = parameters[BDPointEndpointKey];
        NSURL* customEndpointURL = [[NSURL alloc] initWithString:endpointURLString];

        [_authenticationViewController didReceiveRegistrationWithUsername:username
                                                                   apiKey:apiKey
                                                           andPackageName:packageName
                                                                   andURL:customEndpointURL];
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
    // This method implementation must be present in AppDelegate
    // when integrating Bluedot Point SDK v1.x, even if it is empty.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)applicationSignificantTimeChange:(UIApplication *)application
{
}

-(NSDictionary*)parseURLParameters:(NSString*)parameters
{
    NSMutableDictionary* parameterDictionary = [NSMutableDictionary new];
    NSScanner* scanner = [NSScanner scannerWithString:parameters];

    NSCharacterSet* controlCharacters = [NSCharacterSet characterSetWithCharactersInString:@"&="];

    scanner.charactersToBeSkipped = controlCharacters;

    NSString
        *paramName,
        *paramValue;

    while(![scanner isAtEnd])
    {
        if(![scanner scanUpToCharactersFromSet:controlCharacters intoString:&paramName])
            break;

        [scanner setScanLocation:scanner.scanLocation+1];

        if(![scanner scanUpToCharactersFromSet:controlCharacters intoString:&paramValue])
            break;

        parameterDictionary[paramName] = [paramValue urlDecode];
    }

    return [NSDictionary dictionaryWithDictionary:parameterDictionary];
}

-(void)initializeUserInterface
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;

    _authenticationViewController = [BDAuthenticationViewController new];
    _zoneMapViewController        = [BDZoneMapViewController        new];
    _zoneChecklistViewController  = [BDZoneChecklistViewController  new];

    _authenticationViewController.tabBarItem.image = [UIImage imageNamed:@"Authenticate"];
    _zoneMapViewController       .tabBarItem.image = [UIImage imageNamed:@"Map"];
    _zoneChecklistViewController .tabBarItem.image = [UIImage imageNamed:@"Checklist"];

    _viewControllersNotRequiringZoneInfo = @[_authenticationViewController];
    _viewControllersRequiringZoneInfo    = @[_zoneMapViewController, _zoneChecklistViewController];
    
    _tabBarController = [UITabBarController new];
    _tabBarController.delegate = self;
    [_tabBarController setViewControllers:_viewControllersNotRequiringZoneInfo];

    [self startObservingShowFencesOnMapNotifications];

    [self.window setRootViewController:_tabBarController];
    [self.window addSubview:_tabBarController.view];

    [self.window makeKeyAndVisible];
}

/**
* Switches tab-bar controller to the Map view, whenever a BDShowFencesOnMap notification is received
*/
-(void)startObservingShowFencesOnMapNotifications
{
    void (^showFencesNotificationHandler)(NSNotification*) = ^(NSNotification *showFencesNotification)
    {
        NSAssert(BDLocationManager.sharedLocationManager.authenticationState==BDAuthenticationStateAuthenticated, NSInternalInconsistencyException);

        [_tabBarController setSelectedViewController:_zoneMapViewController];
    };

    [NSNotificationCenter.defaultCenter addObserverForName:BDShowFencesOnMapNotification
                                                    object:NULL
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:showFencesNotificationHandler];
}

#pragma mark BDPointDelegate implementation begin

- (void)willAuthenticateWithUsername:(NSString *)username
                              apiKey:(NSString *)apiKey
                         packageName:(NSString *)packageName
{
    NSLog(@"Authenticating with Point service");
}

- (void)authenticationWasSuccessful
{
    NSLog(@"Authenticated successfully with Point service");
}

- (void)authenticationWasDeniedWithReason:(NSString *)reason
{
    NSLog(@"Authentication with Point service denied, with reason: %@", reason);

    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Authentication Denied"
                                                        message:reason
                                                       delegate:NULL
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:NULL];

    [alertView show];
}

- (void)authenticationFailedWithError:(NSError *)error
{
    NSLog(@"Authentication with Point service failed, with reason: %@", error.localizedDescription);

    NSString
        *title,
        *message;

    // BDResponseError will be more conveniently exposed in the next version
    BOOL isConnectionError = error.userInfo[@"BDResponseErrorInfoKeyName"]==NSURLErrorDomain;
    
    if(isConnectionError)
    {
        title   = @"No data connection?";
        message = @"Sorry, but there was a problem connecting to Bluedot servers.\nPlease check you have a data connection, and that flight mode is disabled, and try again.";
    }
    else
    {
        title   = @"Authentication Failed";
        message = error.localizedDescription;
    }
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:NULL
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:NULL];

    [alertView show];
}

- (void)didLogOut
{
    NSLog(@"Logged out");
}

- (void)didUpdateZoneInfo:(NSSet*)zones
{
    NSLog(@"Point service updated with %lu zones", (unsigned long) zones.count);

    NSArray* viewControllers;

    if(zones && zones.count>0)
    {
        viewControllers = [_viewControllersNotRequiringZoneInfo arrayByAddingObjectsFromArray:_viewControllersRequiringZoneInfo];
    }
    else
    {
        viewControllers = _viewControllersNotRequiringZoneInfo;
    }

    [_tabBarController setViewControllers:viewControllers
                                 animated:YES];

    _zoneChecklistViewController.zones = zones;
    _zoneMapViewController.zones       = zones;
}

- (void)didCheckIntoFence:(BDFence *)fence
                   inZone:(BDZoneInfo*)zone
             atCoordinate:(CLLocationCoordinate2D)coordinate
                   onDate:(NSDate *)date
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Application notification"
                                                        message:[NSString stringWithFormat:@"You have checked into fence '%@' in zone '%@', at %@", fence.name, zone.name, date ]
                                                       delegate:NULL
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:NULL];
    [alertView show];

    [_zoneMapViewController didCheckIntoFence:fence];

    [_zoneChecklistViewController didCheckIntoFence:fence
                                             inZone:zone];
}

- (void)userDeniedLocationServices
{
    if(!_locationDeniedDialog)
    {
        NSString
            *appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"],
            *title   = @"Location Services Required",
            *message = [NSString stringWithFormat:@"You have disabled Location Services for this App.  For full functionality, enable this in:\nSettings → Privacy →\nLocation Settings →\n%@ ✓",appName];

        _locationDeniedDialog = [[UIAlertView alloc] initWithTitle:title
                                                           message:message
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];

        [_locationDeniedDialog show];
    }
}

#pragma mark BDPointDelegate implementation end


#pragma mark UITabBarControllerDelegate implementation begin

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    BOOL isDoubleTapOnMap = (viewController == _zoneMapViewController) && (viewController == tabBarController.selectedViewController);

    if(isDoubleTapOnMap)
        [_zoneMapViewController zoomToFitZones];

    return YES;
}

#pragma mark UITabBarControllerDelegate implementation end

@end
