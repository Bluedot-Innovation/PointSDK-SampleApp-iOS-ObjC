//
//  BDLocationChecklistViewController.m
//  BDPoint
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import <BDPointSDK.h>

#import "EXZoneChecklistViewController.h"
#import "EXNotificationStrings.h"
#import "BDStyles.h"


//  Define the constants for this class
static NSString  *fenceCellReuseIdentifier = @"BDFenceCellReuseIdentifier";

static const float  rowHeight = 48.0f;
static const float  buttonInset = 6.0f;
static const float  buttonFontSize = 13.0f;
static const float  switchWidth = 20.0f;


/*
 *  Anonymous category for local properties.
 */
@interface EXZoneChecklistViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) UITableView  *tableView;
@property (nonatomic) NSOrderedSet  *orderedZones;

@property (nonatomic) NSMapTable  *orderedSpatialObjectsByZone;
@property (nonatomic) NSMapTable  *checkedInSpatialObjectsByZone;
@property (nonatomic) NSMapTable  *spatialObjectsForButton;

@property (nonatomic) UIImage  *mapIcon;
@property (nonatomic,copy) NSComparator  nameComparator;

@end


@implementation EXZoneChecklistViewController


- (id)init
{

    if ( ( self = [ super init ] ) != nil )
    {
        //  Set the view properties
        self.title = @"Checklist";

        //  Instantiate the sets and tables
        _orderedZones          = [ NSMutableOrderedSet new ];
        _orderedSpatialObjectsByZone = [ NSMapTable strongToStrongObjectsMapTable ];
        _checkedInSpatialObjectsByZone = [ NSMapTable strongToStrongObjectsMapTable ];
        _spatialObjectsForButton = [ NSMapTable strongToStrongObjectsMapTable ];
        
        //  Define a comparator block
        _nameComparator = ^( id<BDPNamedDescribed> namedA, id<BDPNamedDescribed> namedB )
        {
            return [ namedA.name compare: namedB.name ];
        };

        //  Load in the map icon image from the resources
        _mapIcon = [ UIImage imageNamed: @"Map" ];
    }
    
    return self;
}


/*
 *  Over-ride the loadView to programmatically setup the view.
 */
- (void)loadView
{
    float  statusBarHeight = [ [ UIApplication sharedApplication ] statusBarFrame ].size.height;
    UITableView  *tableView = [ UITableView new ];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    //  Set the delegate for the table as this class
    tableView.dataSource = self;
    tableView.delegate   = self;

    tableView.contentInset = UIEdgeInsetsMake( statusBarHeight, 0.0f, 0.0f, 0.0f );
    self.view = tableView;
}


- (UITableView *)tableView
{
    
    return (UITableView *)self.view;
}


#pragma mark Zones Accessor begin

/*
 *  Over-ride the get and set methods for the zones property.
 */
- (NSSet *)zones
{
    return [ _orderedZones set ];
}

- (void)setZones: (NSSet *)zoneInfos
{
    // Sort Zones
    NSMutableOrderedSet  *mutableOrderedZones = [ [ NSMutableOrderedSet alloc ] initWithSet: zoneInfos ];
    [ mutableOrderedZones sortUsingComparator: _nameComparator ];
    _orderedZones = [ mutableOrderedZones copy ];

    //  Remove all existing spatial objects
    [ _orderedSpatialObjectsByZone removeAllObjects ];
    [ _checkedInSpatialObjectsByZone removeAllObjects ];

    // Sort spatial objects
    for( BDZoneInfo *zone in zoneInfos )
    {
        NSAssert( [ zone.fences isKindOfClass: NSSet.class ], NSInternalInconsistencyException );

        NSMutableOrderedSet  *mutableOrderedSpatialObjects = [ [ NSMutableOrderedSet alloc ] initWithSet: zone.fences ];
        [ mutableOrderedSpatialObjects addObjectsFromArray: zone.beacons.allObjects ];

        [ mutableOrderedSpatialObjects sortUsingComparator: _nameComparator ];
        [ _orderedSpatialObjectsByZone setObject: [ mutableOrderedSpatialObjects copy ]
                                          forKey: zone ];
    }
    
    if ( self.isViewLoaded == YES )
    {
        [ self.tableView reloadData ];
    }
}

#pragma mark Zones Accessor end


- (BDZoneInfo *)zoneForTableSection: (NSUInteger)index
{
    
    return _orderedZones[ index ];
}


- (id <BDPSpatialObject>)spatialObjectAtIndexPath: (NSIndexPath *)indexPath
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)indexPath.section ];
    NSOrderedSet  *spatialObjects = [ _orderedSpatialObjectsByZone objectForKey: zone ];

    return spatialObjects[ (NSUInteger)indexPath.row ];
}

- (void)didCheckIntoSpatialObject: (id<BDPSpatialObject>)spatialObject
                           inZone: (BDZoneInfo *)zone
{
    
    [ _checkedInSpatialObjectsByZone setObject: spatialObject
                                        forKey: zone ];

    [ self.tableView reloadData ];
}


#pragma mark UITableViewDataSource implementation begin

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)section ];

    return( zone.fences.count + zone.beacons.count );
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return _orderedZones.count;
}


- (UIButton *)createShowOnMapButton
{
    UIButton  *showOnMapButton = [ UIButton buttonWithType: UIButtonTypeRoundedRect ];
    
    [ showOnMapButton setImage: _mapIcon forState: UIControlStateNormal ];
    
    showOnMapButton.titleLabel.font = [ UIFont systemFontOfSize: buttonFontSize ];
    showOnMapButton.tintColor = UIColor.whiteColor;
    [ showOnMapButton setTitleColor: UIColor.whiteColor forState: UIControlStateNormal ];
    
    showOnMapButton.backgroundColor = BDBlueColor;
    showOnMapButton.contentEdgeInsets = UIEdgeInsetsMake( buttonInset, buttonInset, buttonInset, buttonInset );
    showOnMapButton.layer.cornerRadius = BDButtonCornerRadii;

    [ showOnMapButton sizeToFit ];

    [ showOnMapButton addTarget: self
                         action: @selector( showOnMapButtonPressed: )
               forControlEvents: UIControlEventTouchUpInside ];

    return showOnMapButton;
}


- (void)showOnMapButtonPressed: (UIButton *)button
{
    id<BDPSpatialObject>  spatialObject = [_spatialObjectsForButton objectForKey: button ];
    NSNotification  *notification = [ NSNotification notificationWithName: EXShowFencesOnMapNotification
                                                                   object: spatialObject ];

    [ NSNotificationCenter.defaultCenter postNotification: notification ];
}


- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell  *cell = [ tableView dequeueReusableCellWithIdentifier: fenceCellReuseIdentifier ];
    UIButton  *showOnMapButton;

    if ( cell != nil )
    {
        showOnMapButton = (UIButton *)cell.accessoryView;
    }
    else
    {
        cell = [ [ UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                        reuseIdentifier: fenceCellReuseIdentifier ];

        showOnMapButton = [ self createShowOnMapButton ];
        cell.accessoryView = showOnMapButton;
    }

    id<BDPSpatialObject>  spatialObject = [self spatialObjectAtIndexPath:indexPath];

    [ _spatialObjectsForButton setObject: spatialObject
                                  forKey: showOnMapButton ];

    NSString  *name;
    NSString  *description;

    if( [ spatialObject isKindOfClass:BDFence.class ] == YES )
    {
        BDFence *fence = (BDFence*)spatialObject;

        name        = fence.name;
        description = fence.description;
    }
    else if( [ spatialObject isKindOfClass:BDBeacon.class ] == YES )
    {
        BDBeacon *beacon = (BDBeacon*)spatialObject;

        name        = beacon.name;
        description = beacon.description;
    }
    else
    {
        @throw [ NSException exceptionWithName: @"EXUnknownObjectException"
                                        reason: @"Unsupported spatial object"
                                      userInfo: nil ];
    }

    cell.textLabel.text       = name;
    cell.detailTextLabel.text = description;

    return cell;
}


/*
 *  Create a view for the table headers to allow a switch to be embedded within.
 */
- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section
{
    BDZoneInfo  *zone = _orderedZones[ (NSUInteger)section ];
    CGRect frame = tableView.frame;
    float  height = rowHeight - ( buttonInset * 2.0f );

    //  Instantiate a switch with a standard size
    UISwitch *zoneSwitch = [ [ UISwitch alloc ] initWithFrame: CGRectZero ];
    [ zoneSwitch addTarget: self action: @selector( switchToggled: ) forControlEvents: UIControlEventTouchUpInside ];
    zoneSwitch.tag = section;

    CGRect  switchPosition = CGRectMake( frame.size.width - zoneSwitch.frame.size.width - buttonInset, buttonInset,
                                         zoneSwitch.frame.size.width, zoneSwitch.frame.size.height );
    zoneSwitch.frame = switchPosition;
    zoneSwitch.onTintColor = [ UIColor redColor ];
    zoneSwitch.on = ![ BDLocationManager.instance isZoneDisabledByApplication:zone.ID ];

    UILabel *title = [ [ UILabel alloc ] initWithFrame: CGRectMake( buttonInset, buttonInset,
                                                                    frame.size.width - switchWidth - ( buttonInset * 2.0f ), height ) ];
    title.text = zone.name;

    UIView *headerView = [ [ UIView alloc ] initWithFrame: CGRectMake( 0, 0, frame.size.width, rowHeight ) ];
    headerView.backgroundColor = UIColorFromRGB( 0x8AB8d5 );
    [ headerView addSubview: title ];
    [ headerView addSubview: zoneSwitch ];

    return headerView;
}

#pragma mark UITableViewDataSource implementation end


#pragma mark UITableViewDelegate implementation begin

- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
    
    return rowHeight;
}


- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection: (NSInteger)section
{
    
    return rowHeight;
}


- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    
    [ tableView deselectRowAtIndexPath: indexPath animated: NO ];
}

#pragma mark UITableViewDelegate implementation end

/*
 *  Process the selected switch state to determine if the zone is to be disabled or re-enabled.
 */
- (void)switchToggled: (id)sender
{
    UISwitch  *zoneSwitch = (UISwitch *)sender;
    BDZoneInfo  *zone = _orderedZones[ (NSUInteger)zoneSwitch.tag ];


    //  If the switch is set to on, then the zone is to be disabled
    [ [ BDLocationManager instance ] setZone: zone.ID disableByApplication: [ zoneSwitch isOn ] ];
}
@end
