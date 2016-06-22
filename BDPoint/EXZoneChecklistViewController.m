//
//  Created by Bluedot Innovation
//  Copyright (c) 2016 Bluedot Innovation. All rights reserved.
//
//  View Controller to list all the zones and spatial objects.
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
@property (nonatomic,copy) NSComparator  spatialNameComparator;
@property (nonatomic,copy) NSComparator  zoneNameComparator;

@end


@implementation EXZoneChecklistViewController

- (id)init
{

    if ( ( self = [ super init ] ) != nil )
    {
        //  Set the view properties
        self.title = @"Checklist";

        //  Instantiate the sets and tables
        _orderedZones = [ NSMutableOrderedSet new ];
        _orderedSpatialObjectsByZone = [ NSMapTable strongToStrongObjectsMapTable ];
        _checkedInSpatialObjectsByZone = [ NSMapTable strongToStrongObjectsMapTable ];
        _spatialObjectsForButton = [ NSMapTable strongToStrongObjectsMapTable ];
        
        //  Define a comparator block for spatial objects
        _spatialNameComparator = ^( id<BDPSpatialObjectInfo> nameA, id<BDPSpatialObjectInfo> nameB )
        {
            return [ nameA.name compare: nameB.name ];
        };
        
        //  Define a comparator block for zone infos
        _zoneNameComparator = ^( BDZoneInfo *zoneNameA, BDZoneInfo *zoneNameB )
        {
            return [ zoneNameA.name compare: zoneNameB.name ];
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

/*
 *  Order the zone information into a set of zones ordered by name.
 *  For each of the zones, order the spatial objects by name and store the ordered set in a map, keyed by the zone object.
 */
- (void)setZones: (NSSet *)zoneInfos
{
    // Sort Zones
    NSMutableOrderedSet  *mutableOrderedZones = [ [ NSMutableOrderedSet alloc ] initWithSet: zoneInfos ];
    [ mutableOrderedZones sortUsingComparator: _zoneNameComparator ];
    _orderedZones = [ mutableOrderedZones copy ];

    //  Remove all existing spatial objects
    [ _orderedSpatialObjectsByZone removeAllObjects ];
    [ _checkedInSpatialObjectsByZone removeAllObjects ];

    // Sort spatial objects for each zone
    for( BDZoneInfo *zone in zoneInfos )
    {
        NSAssert( [ zone.fences isKindOfClass: NSSet.class ], NSInternalInconsistencyException );

        NSMutableOrderedSet  *mutableOrderedSpatialObjects = [ [ NSMutableOrderedSet alloc ] initWithSet: zone.fences ];
        [ mutableOrderedSpatialObjects addObjectsFromArray: zone.beacons.allObjects ];

        [ mutableOrderedSpatialObjects sortUsingComparator: _spatialNameComparator ];
        [ _orderedSpatialObjectsByZone setObject: [ mutableOrderedSpatialObjects copy ]
                                          forKey: zone ];
    }
    
    //  If the table has already been loaded into memory, then reload the data
    if ( self.isViewLoaded == YES )
    {
        [ self.tableView reloadData ];
    }
}

#pragma mark Zones Accessor end

/*
 *  Wrapper method to retrieve the zone for an specified index of the table.
 */
- (BDZoneInfo *)zoneForTableSection: (NSUInteger)index
{
    return _orderedZones[ index ];
}

/*
 *  Wrapper method to retrieve the spatial object (fence or beacon) from a row of the table.
 */
- (id)spatialObjectAtIndexPath: (NSIndexPath *)indexPath
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)indexPath.section ];
    NSOrderedSet  *spatialObjects = [ _orderedSpatialObjectsByZone objectForKey: zone ];

    return spatialObjects[ (NSUInteger)indexPath.row ];
}

/*
 *  Wrapper method to determine if a spatial object from a row of the table has been checked into.
 */
- (BOOL)isSpatialObjectCheckedIn: (id<BDPSpatialObjectInfo>)spatialObject atIndexPath: (NSIndexPath *)indexPath
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)indexPath.section ];
    NSMutableSet  *objects = [ _checkedInSpatialObjectsByZone objectForKey: zone ];
    
    return [ objects containsObject: spatialObject ];
}

/*
 *  Add a fence with a Custom Action that has been checked into to the map of Check-Ins.
 */
- (void)didCheckIntoFence: (BDFenceInfo *)fence
                   inZone: (BDZoneInfo *)zone
{
    [ self addCheckedInSpatialObject: fence forZone: zone ];
    
    [ self.tableView reloadData ];
}

/*
 *  Add a beacon with a Custom Action that has been checked into to the map of Check-Ins.
 */
- (void)didCheckIntoBeacon:(BDBeaconInfo *)beacon
                    inZone:(BDZoneInfo *)zone
{
    [ self addCheckedInSpatialObject: beacon forZone: zone ];
    
    [ self.tableView reloadData ];
}

/*
 *  Store the Check-Ins made into a set of spatial objects mapped to the zone.
 */
- (void)addCheckedInSpatialObject: (id<BDPSpatialObjectInfo>)spatialObject forZone: (BDZoneInfo *)zone
{
    NSMutableSet  *objects = [ _checkedInSpatialObjectsByZone objectForKey: zone ];
    
    //  Create a set of fences for the zone if none yet exists
    if (  objects == nil )
    {
        objects = [ NSMutableSet new ];
    }
    
    [ objects addObject: spatialObject ];
    
    //  Update the spatial objects set for the mapped zone
    [ _checkedInSpatialObjectsByZone setObject: objects
                                        forKey: zone ];
}


#pragma mark UITableViewDataSource implementation begin

/*
 *  Determine the number of rows in the table; ensure that both fences and beacons are counted.
 */
- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)section ];

    return( zone.fences.count + zone.beacons.count );
}

/*
 *  A zone is used for each section of the table.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _orderedZones.count;
}

/*
 *  Create a button to show the location of a spatial object (fence or beacon) on the map.
 */
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

/*
 *  When the button is pressed, show the location on the map of the associated spatial object.
 */
- (void)showOnMapButtonPressed: (UIButton *)button
{
    id  spatialObject = [ _spatialObjectsForButton objectForKey: button ];
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

    //  Obtain the spatial object for this cell
    id<BDPSpatialObjectInfo>  spatialObject = [ self spatialObjectAtIndexPath: indexPath ];

    //  Map this spatial object to the button
    [ _spatialObjectsForButton setObject: spatialObject
                                  forKey: showOnMapButton ];

    cell.detailTextLabel.text = spatialObject.description;
    
    if ( [ self isSpatialObjectCheckedIn: spatialObject atIndexPath: indexPath ] == YES )
    {
        cell.textLabel.text = [ NSString stringWithFormat: @"%@ ✓", spatialObject.name ];
    }
    else
    {
        cell.textLabel.text = spatialObject.name;
    }
    
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

    CGRect  switchPosition = CGRectMake( frame.size.width - zoneSwitch.frame.size.width - buttonInset, buttonInset, zoneSwitch.frame.size.width, zoneSwitch.frame.size.height );
    zoneSwitch.frame = switchPosition;
    zoneSwitch.onTintColor = [ UIColor redColor ];
    
    BOOL isZoneDisabledByApplication = [ BDLocationManager.instance isZoneDisabledByApplication: zone.ID ];
    zoneSwitch.on = isZoneDisabledByApplication;

    CGRect titleRect = CGRectMake( buttonInset, buttonInset, frame.size.width - switchWidth - ( buttonInset * 2.0f ), height );
    UILabel *title = [ [ UILabel alloc ] initWithFrame: titleRect ];
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
