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
static const float  showOnMapButtonTitlePadding = 6.0f;
static const float  buttonFontSize = 13.0f;


/*
 *  Anonymous category for local properties.
 */
@interface EXZoneChecklistViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) UITableView  *tableView;
@property (nonatomic) NSOrderedSet  *orderedZones;

@property (nonatomic) NSMapTable  *orderedFencesByZone;
@property (nonatomic) NSMapTable  *checkedInFencesByZone;
@property (nonatomic) NSMapTable  *fencesForButton;

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
        _orderedFencesByZone   = [ NSMapTable strongToStrongObjectsMapTable ];
        _checkedInFencesByZone = [ NSMapTable strongToStrongObjectsMapTable ];
        _fencesForButton       = [ NSMapTable strongToStrongObjectsMapTable ];
        
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
    UITableView  *tableView = [ UITableView new ];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    //  Set the delegate for the table as this class
    tableView.dataSource = self;
    tableView.delegate   = self;
    
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

    //  Remove all existing fences
    [_orderedFencesByZone   removeAllObjects];
    [_checkedInFencesByZone removeAllObjects];

    // Sort Fences
    for( BDZoneInfo *zone in zoneInfos )
    {
        NSAssert( [ zone.fences isKindOfClass: NSSet.class ], NSInternalInconsistencyException );

        NSMutableOrderedSet  *mutableOrderedFences = [ [ NSMutableOrderedSet alloc ] initWithSet: zone.fences ];
        [ mutableOrderedFences sortUsingComparator: _nameComparator ];
        [ _orderedFencesByZone setObject: [ mutableOrderedFences copy ] forKey: zone ];
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


- (BDFence *)fenceAtIndexPath: (NSIndexPath *)indexPath
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)indexPath.section ];
    NSOrderedSet  *fences = [ _orderedFencesByZone objectForKey: zone ];

    return fences[ (NSUInteger)indexPath.row ];
}

- (void)didCheckIntoFence: (BDFence *)fence inZone: (BDZoneInfo *)zone
{
    
    [ _checkedInFencesByZone setObject: fence
                                forKey: zone ];

    [ self.tableView reloadData ];
}


#pragma mark UITableViewDataSource implementation begin

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
    BDZoneInfo  *zone = [ self zoneForTableSection: (NSUInteger)section ];

    return zone.fences.count;
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
    showOnMapButton.contentEdgeInsets = UIEdgeInsetsMake( showOnMapButtonTitlePadding, showOnMapButtonTitlePadding, showOnMapButtonTitlePadding, showOnMapButtonTitlePadding );
    showOnMapButton.layer.cornerRadius = BDButtonCornerRadii;

    [ showOnMapButton sizeToFit ];

    [ showOnMapButton addTarget: self
                         action: @selector( showOnMapButtonPressed: )
               forControlEvents: UIControlEventTouchUpInside ];

    return showOnMapButton;
}


- (void)showOnMapButtonPressed: (UIButton *)button
{
    NSSet  *fences = [ _fencesForButton objectForKey: button ];
    NSNotification  *notification = [ NSNotification notificationWithName: EXShowFencesOnMapNotification
                                                                   object: fences ];

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

    NSSet  *fenceSet = [ NSSet setWithObject: [ self fenceAtIndexPath: indexPath ] ];
    [ _fencesForButton setObject: fenceSet forKey: showOnMapButton ];

    BDFence  *fence = [ self fenceAtIndexPath: indexPath ];

    cell.textLabel.text = fence.name;
    cell.detailTextLabel.text = fence.description;

    return cell;
}


- (NSString *)tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
    BDZoneInfo  *zone = _orderedZones[ (NSUInteger)section ];

    return zone.name;
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

@end
