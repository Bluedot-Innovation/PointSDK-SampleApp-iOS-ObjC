//
//  BDLocationChecklistViewController.m
//  BDPointSampleApp
//
//  Created by Christopher Hatton on 14/06/2014.
//  Copyright (c) 2014 Bluedot. All rights reserved.
//

#import "BDZoneChecklistViewController.h"
#import "NSObject+BDKVOBlocks.h"
#import "BDFocusFencesNotification.h"
#import "BDStyles.h"
#import <BDPointSDK.h>

#define BDFenceCellReuseIdentifier @"BDFenceCellReuseIdentifier"

#define BDRowHeight 48.0f
#define BDShowOnMapButtonTitlePadding 6.0f

@interface BDZoneChecklistViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) UITableView* tableView;

@property (nonatomic) NSOrderedSet* orderedZones;
@property (nonatomic) NSMapTable
    *orderedFencesByZone,
    *checkedInFencesByZone,
    *fencesForButton;

@property (nonatomic,copy) NSComparator  nameComparator;

@property (nonatomic) UIImage* mapIcon;

@end


@implementation BDZoneChecklistViewController

-(id)init
{
    self = [super init];
    if(self)
    {
        self.title = @"Checklist";

        _orderedZones          = [NSMapTable strongToStrongObjectsMapTable];
        _orderedFencesByZone   = [NSMapTable strongToStrongObjectsMapTable];
        _checkedInFencesByZone = [NSMapTable strongToStrongObjectsMapTable];
        _fencesForButton       = [NSMapTable strongToStrongObjectsMapTable];
        
        _nameComparator = ^(id<BDPNamedDescribed> namedA, id<BDPNamedDescribed> namedB)
        {
            return [namedA.name compare:namedB.name];
        };

        _mapIcon = [UIImage imageNamed:@"Map"];
    }
    return self;
}

-(void)loadView
{
    UITableView* tableView = [UITableView new];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    tableView.dataSource = self;
    tableView.delegate   = self;
    
    self.view = tableView;
}

-(UITableView*)tableView
{
    return (UITableView*)self.view;
}


#pragma mark Zones Accessor begin

-(void)setZones:(NSSet *)zoneInfos
{
    // Sort Zones

    NSMutableOrderedSet* mutableOrderedZones = [[NSMutableOrderedSet alloc] initWithSet:zoneInfos];
    [mutableOrderedZones sortUsingComparator:_nameComparator];
    _orderedZones = [mutableOrderedZones copy];


    // Sort Fences

    [_orderedFencesByZone   removeAllObjects];
    [_checkedInFencesByZone removeAllObjects];

    NSSet* fences;
    for(BDZoneInfo* zone in zoneInfos)
    {
        fences = zone.fences;
        NSAssert([fences isKindOfClass:NSSet.class], NSInternalInconsistencyException);

        NSMutableOrderedSet* mutableOrderedFences = [[NSMutableOrderedSet alloc] initWithSet:fences];
        [mutableOrderedFences sortUsingComparator:_nameComparator];
        [_orderedFencesByZone setObject:[mutableOrderedFences copy] forKey:zone];
    }

    if(!self.isViewLoaded)
        [self.tableView reloadData];
}

-(NSSet*)zones
{
    return [_orderedZones set];
}

#pragma mark Zones Accessor end


- (BDZoneInfo*)zoneForTableSection:(NSUInteger)index
{
    return _orderedZones[index];
}

- (BDFence*)fenceAtIndexPath:(NSIndexPath*)indexPath
{
    BDZoneInfo*   zone   = [self zoneForTableSection:(NSUInteger)indexPath.section];
    NSOrderedSet* fences = [_orderedFencesByZone objectForKey:zone];

    return fences[(NSUInteger)indexPath.row];
}

- (void)didCheckIntoFence:(BDFence*)fence inZone:(BDZoneInfo*)zone
{
    [_checkedInFencesByZone setObject:fence
                               forKey:zone];

    [self.tableView reloadData];
}


#pragma mark UITableViewDataSource implementation begin

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BDZoneInfo* zone = [self zoneForTableSection:(NSUInteger)section];

    return zone.fences.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _orderedZones.count;
}

-(UIButton*)createShowOnMapButton
{
    UIButton* showOnMapButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [showOnMapButton setImage:_mapIcon forState:UIControlStateNormal];
    showOnMapButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    showOnMapButton.tintColor = UIColor.whiteColor;
    [showOnMapButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    showOnMapButton.backgroundColor = BDBlueColor;
    showOnMapButton.contentEdgeInsets = UIEdgeInsetsMake(BDShowOnMapButtonTitlePadding, BDShowOnMapButtonTitlePadding, BDShowOnMapButtonTitlePadding, BDShowOnMapButtonTitlePadding);
    showOnMapButton.layer.cornerRadius = BDButtonCornerRadii;

    [showOnMapButton sizeToFit];

    [showOnMapButton addTarget:self
                        action:@selector(showOnMapButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];

    return showOnMapButton;
}

-(void)showOnMapButtonPressed:(UIButton*)button
{
    NSSet* fences = [_fencesForButton objectForKey:button];

    NSNotification* notification = [NSNotification notificationWithName:BDShowFencesOnMapNotification
                                                                 object:fences];

    [NSNotificationCenter.defaultCenter postNotification:notification];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:BDFenceCellReuseIdentifier];

    UIButton* showOnMapButton;

    if(cell)
    {
        showOnMapButton = (UIButton*)cell.accessoryView;
    }
    else
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:BDFenceCellReuseIdentifier];

        showOnMapButton = [self createShowOnMapButton];

        cell.accessoryView = showOnMapButton;
    }

    NSSet* fenceSet = [NSSet setWithObject:[self fenceAtIndexPath:indexPath]];
    [_fencesForButton setObject:fenceSet forKey:showOnMapButton];

    BDFence* fence = [self fenceAtIndexPath:indexPath];

    cell.textLabel.text       = fence.name;
    cell.detailTextLabel.text = fence.description;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BDZoneInfo* zone = _orderedZones[(NSUInteger)section];

    return zone.name;
}


#pragma mark UITableViewDataSource implementation end


#pragma mark UITableViewDelegate implementation begin

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BDRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return BDRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark UITableViewDelegate implementation end

@end
