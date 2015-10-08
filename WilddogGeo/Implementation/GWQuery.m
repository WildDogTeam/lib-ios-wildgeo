//
//  GWQuery.m
//  WilddogGeo
//
//  Created by Jonny Dimond on 7/3/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import "GWQuery.h"
#import "GWRegionQuery.h"
#import "GWCircleQuery.h"
#import "GWQuery+Private.h"
#import "WilddogGeo.h"
#import "WilddogGeo+Private.h"
#import "GWGeoHashQuery.h"
#import <Wilddog/Wilddog.h>

@interface GWQueryLocationInfo : NSObject

@property (nonatomic) BOOL isInQuery;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) GWGeoHash *geoHash;

@end

@implementation GWQueryLocationInfo
@end

@interface GWGeoHashQueryHandle : NSObject

@property (nonatomic) wilddogHandle childAddedHandle;
@property (nonatomic) wilddogHandle childRemovedHandle;
@property (nonatomic) wilddogHandle childChangedHandle;

@end

@implementation GWGeoHashQueryHandle

@end

@interface GWCircleQuery ()

@property (nonatomic, strong) CLLocation *centerLocation;

@end

@implementation GWCircleQuery

@synthesize radius = _radius;

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire
             location:(CLLocation *)location
               radius:(double)radius
{
    self = [super initWithWilddogGeo:geoFire];
    if (self != nil) {
        if (!CLLocationCoordinate2DIsValid(location.coordinate)) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Not a valid geo location: [%f,%f]",
             location.coordinate.latitude, location.coordinate.longitude];
        }
        _centerLocation = location;
        _radius = radius;
    }
    return self;
}

- (void)setCenter:(CLLocation *)center
{
    @synchronized(self) {
        if (!CLLocationCoordinate2DIsValid(center.coordinate)) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Not a valid geo location: [%f,%f]",
             center.coordinate.latitude, center.coordinate.longitude];
        }
        _centerLocation = center;
        [self searchCriteriaDidChange];
    }
}

- (CLLocation *)center
{
    @synchronized(self) {
        return self.centerLocation;
    }
}

- (void)setRadius:(double)radius
{
    @synchronized(self) {
        _radius = radius;
        [self searchCriteriaDidChange];
    }
}

- (double)radius
{
    @synchronized(self) {
        return _radius;
    }
}

- (BOOL)locationIsInQuery:(CLLocation *)location
{
    return [location distanceFromLocation:self.centerLocation] <= (self.radius * 1000);
}

- (NSSet *)queriesForCurrentCriteria
{
    return [GWGeoHashQuery queriesForLocation:self.centerLocation.coordinate radius:(self.radius * 1000)];
}

@end

@interface GWRegionQuery ()

@end

@implementation GWRegionQuery

@synthesize region = _region;

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire
               region:(MKCoordinateRegion)region;
{
    self = [super initWithWilddogGeo:geoFire];
    if (self != nil) {
        _region = region;
    }
    return self;
}

- (void)setRegion:(MKCoordinateRegion)region
{
    @synchronized(self) {
        _region = region;
        [self searchCriteriaDidChange];
    }
}

- (MKCoordinateRegion)region
{
    @synchronized(self) {
        return _region;
    }
}

- (BOOL)locationIsInQuery:(CLLocation *)location
{
    MKCoordinateRegion region = self.region;
    CLLocationDegrees north = region.center.latitude + region.span.latitudeDelta/2;
    CLLocationDegrees south = region.center.latitude - region.span.latitudeDelta/2;
    CLLocationDegrees west = region.center.longitude - region.span.longitudeDelta/2;
    CLLocationDegrees east = region.center.longitude + region.span.longitudeDelta/2;

    CLLocationCoordinate2D coordinate = location.coordinate;
    return (coordinate.latitude <= north && coordinate.latitude >= south &&
            coordinate.longitude >= west && coordinate.longitude <= east);
}

- (NSSet *)queriesForCurrentCriteria
{
    return [GWGeoHashQuery queriesForRegion:self.region];
}

@end


@interface GWQuery ()

@property (nonatomic, strong) NSMutableDictionary *locationInfos;
@property (nonatomic, strong) WilddogGeo *geoFire;
@property (nonatomic, strong) NSSet *queries;
@property (nonatomic, strong) NSMutableDictionary *wilddogHandles;
@property (nonatomic, strong) NSMutableSet *outstandingQueries;

@property (nonatomic, strong) NSMutableDictionary *keyEnteredObservers;
@property (nonatomic, strong) NSMutableDictionary *keyExitedObservers;
@property (nonatomic, strong) NSMutableDictionary *keyMovedObservers;
@property (nonatomic, strong) NSMutableDictionary *readyObservers;
@property (nonatomic) NSUInteger currentHandle;

@end

@implementation GWQuery

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire
{
    self = [super init];
    if (self != nil) {
        _geoFire = geoFire;
        _currentHandle = 1;
        [self reset];
    }
    return self;
}

- (WQuery *)wilddogForGeoHashQuery:(GWGeoHashQuery *)query
{
    return [[[self.geoFire.wilddogRef queryOrderedByChild:@"g"] queryStartingAtValue:query.startValue]
            queryEndingAtValue:query.endValue];
}

- (void)updateLocationInfo:(CLLocation *)location
                    forKey:(NSString *)key
{
    NSAssert(location != nil, @"Internal Error! Location must not be nil!");
    GWQueryLocationInfo *info = self.locationInfos[key];
    BOOL isNew = NO;
    if (info == nil) {
        isNew = YES;
        info = [[GWQueryLocationInfo alloc] init];
        self.locationInfos[key] = info;
    }
    BOOL changedLocation = !(info.location.coordinate.latitude == location.coordinate.latitude &&
                             info.location.coordinate.longitude == location.coordinate.longitude);
    BOOL wasInQuery = info.isInQuery;

    info.location = location;
    info.isInQuery = [self locationIsInQuery:location];
    info.geoHash = [GWGeoHash newWithLocation:location.coordinate];

    if ((isNew || !wasInQuery) && info.isInQuery) {
        [self.keyEnteredObservers enumerateKeysAndObjectsUsingBlock:^(id observerKey,
                                                                      GWQueryResultBlock block,
                                                                      BOOL *stop) {
            dispatch_async(self.geoFire.callbackQueue, ^{
                block(key, info.location);
            });
        }];
    } else if (!isNew && changedLocation && info.isInQuery) {
        [self.keyMovedObservers enumerateKeysAndObjectsUsingBlock:^(id observerKey,
                                                                    GWQueryResultBlock block,
                                                                    BOOL *stop) {
            dispatch_async(self.geoFire.callbackQueue, ^{
                block(key, info.location);
            });
        }];
    } else if (wasInQuery && !info.isInQuery) {
        [self.keyExitedObservers enumerateKeysAndObjectsUsingBlock:^(id observerKey,
                                                                     GWQueryResultBlock block,
                                                                     BOOL *stop) {
            dispatch_async(self.geoFire.callbackQueue, ^{
                block(key, info.location);
            });
        }];
    }
}

- (BOOL)queriesContainGeoHash:(GWGeoHash *)geoHash
{
    for (GWGeoHashQuery *query in self.queries) {
        if ([query containsGeoHash:geoHash]) {
            return YES;
        }
    }
    return NO;
}

- (void)childAdded:(WDataSnapshot *)snapshot
{
    @synchronized(self) {
        CLLocation *location = [WilddogGeo locationFromValue:snapshot.value];
        if (location != nil) {
            [self updateLocationInfo:location forKey:snapshot.key];
        } else {
            // TODO: error?
        }
    }
}

- (void)childChanged:(WDataSnapshot *)snapshot
{
    @synchronized(self) {
        CLLocation *location = [WilddogGeo locationFromValue:snapshot.value];
        if (location != nil) {
            [self updateLocationInfo:location forKey:snapshot.key];
        } else {
            // TODO: error?
        }
    }
}

- (void)childRemoved:(WDataSnapshot *)snapshot
{
    @synchronized(self) {
        NSString *key = snapshot.key;
        GWQueryLocationInfo *info = self.locationInfos[snapshot.key];
        if (info != nil) {
            [[self.geoFire wilddogRefForLocationKey:snapshot.key] observeSingleEventOfType:WEventTypeValue withBlock:^(WDataSnapshot *snapshot) {
                @synchronized(self) {
                    CLLocation *location = [WilddogGeo locationFromValue:snapshot.value];
                    GWGeoHash *geoHash = (location) ? [[GWGeoHash alloc] initWithLocation:location.coordinate] : nil;
                    // Only notify observers if key is not part of any other geohash query or this actually might not be
                    // a key exited event, but a key moved or entered event. These events will be triggered by updates
                    // to a different query
                    if (![self queriesContainGeoHash:geoHash]) {
                        GWQueryLocationInfo *info = self.locationInfos[key];
                        [self.locationInfos removeObjectForKey:key];
                        // Key was in query, notify about key exited
                        if (info.isInQuery) {
                            [self.keyExitedObservers enumerateKeysAndObjectsUsingBlock:^(id observerKey,
                                                                                         GWQueryResultBlock block,
                                                                                         BOOL *stop) {
                                dispatch_async(self.geoFire.callbackQueue, ^{
                                    block(key, location);
                                });
                            }];
                        }
                    }
                }
            }];
        }
    }
}

- (BOOL)locationIsInQuery:(CLLocation *)location
{
    [NSException raise:NSInternalInconsistencyException format:@"GWQuery is abstract, please implement locationIsInQuery:"];
    return NO;
}

- (NSSet *)queriesForCurrentCriteria
{
    [NSException raise:NSInternalInconsistencyException format:@"GWQuery is abstract, please implement queriesForCurrentCriteria"];
    return nil;
}

- (void)searchCriteriaDidChange
{
    if (self.queries != nil) {
        [self updateQueries];
    }
}

- (void)checkAndFireReadyEvent
{
    if (self.outstandingQueries.count == 0) {
        [self.readyObservers enumerateKeysAndObjectsUsingBlock:^(id key, GFReadyBlock block, BOOL *stop) {
            dispatch_async(self.geoFire.callbackQueue, block);
        }];
    }
}

- (void)updateQueries
{
    NSSet *oldQueries = self.queries;
    NSSet *newQueries = [self queriesForCurrentCriteria];
    NSMutableSet *toDelete = [NSMutableSet setWithSet:oldQueries];
    [toDelete minusSet:newQueries];
    NSMutableSet *toAdd = [NSMutableSet setWithSet:newQueries];
    [toAdd minusSet:oldQueries];
    [toDelete enumerateObjectsUsingBlock:^(GWGeoHashQuery *query, BOOL *stop) {
        GWGeoHashQueryHandle *handle = self.wilddogHandles[query];
        if (handle == nil) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Wanted to remove a geohash query that was not registered!"];
        }
        WQuery *querywilddog = [self wilddogForGeoHashQuery:query];
        [querywilddog removeObserverWithHandle:handle.childAddedHandle];
        [querywilddog removeObserverWithHandle:handle.childChangedHandle];
        [querywilddog removeObserverWithHandle:handle.childRemovedHandle];
        [self.wilddogHandles removeObjectForKey:handle];
        [self.outstandingQueries removeObject:query];
    }];
    [toAdd enumerateObjectsUsingBlock:^(GWGeoHashQuery *query, BOOL *stop) {
        [self.outstandingQueries addObject:query];
        GWGeoHashQueryHandle *handle = [[GWGeoHashQueryHandle alloc] init];
        WQuery *querywilddog = [self wilddogForGeoHashQuery:query];
        handle.childAddedHandle = [querywilddog observeEventType:WEventTypeChildAdded
                                                        withBlock:^(WDataSnapshot *snapshot) {
                                                            [self childAdded:snapshot];
                                                        }];
        handle.childChangedHandle = [querywilddog observeEventType:WEventTypeChildChanged
                                                          withBlock:^(WDataSnapshot *snapshot) {
                                                              [self childChanged:snapshot];
                                                          }];
        handle.childRemovedHandle = [querywilddog observeEventType:WEventTypeChildRemoved
                                                          withBlock:^(WDataSnapshot *snapshot) {
                                                              [self childRemoved:snapshot];
                                                          }];
        [querywilddog observeSingleEventOfType:WEventTypeValue
                                      withBlock:^(WDataSnapshot *snapshot) {
                                          @synchronized(self) {
                                              [self.outstandingQueries removeObject:query];
                                              [self checkAndFireReadyEvent];
                                          }
                                      }];
        self.wilddogHandles[query] = handle;
    }];
    self.queries = newQueries;
    [self.locationInfos enumerateKeysAndObjectsUsingBlock:^(id key, GWQueryLocationInfo *info, BOOL *stop) {
        [self updateLocationInfo:info.location forKey:key];
    }];
    NSMutableArray *oldLocations = [NSMutableArray array];
    [self.locationInfos enumerateKeysAndObjectsUsingBlock:^(id key, GWQueryLocationInfo *info, BOOL *stop) {
        if (![self queriesContainGeoHash:info.geoHash]) {
            [oldLocations addObject:key];
        }
    }];
    [self.locationInfos removeObjectsForKeys:oldLocations];

    [self checkAndFireReadyEvent];
}

- (void)reset
{
    for (GWGeoHashQuery *query in self.queries) {
        GWGeoHashQueryHandle *handle = self.wilddogHandles[query];
        if (handle == nil) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Wanted to remove a geohash query that was not registered!"];
        }
        WQuery *querywilddog = [self wilddogForGeoHashQuery:query];
        [querywilddog removeObserverWithHandle:handle.childAddedHandle];
        [querywilddog removeObserverWithHandle:handle.childChangedHandle];
        [querywilddog removeObserverWithHandle:handle.childRemovedHandle];
    }
    self.wilddogHandles = [NSMutableDictionary dictionary];
    self.queries = nil;
    self.outstandingQueries = [NSMutableSet set];
    self.keyEnteredObservers = [NSMutableDictionary dictionary];
    self.keyExitedObservers = [NSMutableDictionary dictionary];
    self.keyMovedObservers = [NSMutableDictionary dictionary];
    self.readyObservers = [NSMutableDictionary dictionary];
    self.locationInfos = [NSMutableDictionary dictionary];
}

- (void)removeAllObservers
{
    @synchronized(self) {
        [self reset];
    }
}

- (void)removeObserverWithwilddogHandle:(wilddogHandle)wilddogHandle
{
    @synchronized(self) {
        NSNumber *handle = [NSNumber numberWithUnsignedInteger:wilddogHandle];
        [self.keyEnteredObservers removeObjectForKey:handle];
        [self.keyExitedObservers removeObjectForKey:handle];
        [self.keyMovedObservers removeObjectForKey:handle];
        [self.readyObservers removeObjectForKey:handle];
        if ([self totalObserverCount] == 0) {
            [self reset];
        }
    }
}

- (NSUInteger)totalObserverCount
{
    return (self.keyEnteredObservers.count +
            self.keyExitedObservers.count +
            self.keyMovedObservers.count +
            self.readyObservers.count);
}

- (wilddogHandle)observeEventType:(GFEventType)eventType withBlock:(GWQueryResultBlock)block
{
    @synchronized(self) {
        if (block == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Block is not allowed to be nil!"];
        }
        wilddogHandle wilddogHandle = self.currentHandle++;
        NSNumber *numberHandle = [NSNumber numberWithUnsignedInteger:wilddogHandle];
        switch (eventType) {
            case GFEventTypeKeyEntered: {
                [self.keyEnteredObservers setObject:[block copy]
                                             forKey:numberHandle];
                self.currentHandle++;
                dispatch_async(self.geoFire.callbackQueue, ^{
                    @synchronized(self) {
                        [self.locationInfos enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                                                GWQueryLocationInfo *info,
                                                                                BOOL *stop) {
                            if (info.isInQuery) {
                                block(key, info.location);
                            }
                        }];
                    };
                });
                break;
            }
            case GFEventTypeKeyExited: {
                [self.keyExitedObservers setObject:[block copy]
                                            forKey:numberHandle];
                self.currentHandle++;
                break;
            }
            case GFEventTypeKeyMoved: {
                [self.keyMovedObservers setObject:[block copy]
                                           forKey:numberHandle];
                self.currentHandle++;
                break;
            }
            default: {
                [NSException raise:NSInvalidArgumentException format:@"Event type was not a GFEventType!"];
                break;
            }
        }
        if (self.queries == nil) {
            [self updateQueries];
        }
        return wilddogHandle;
    }
}

- (wilddogHandle)observeReadyWithBlock:(GFReadyBlock)block
{
    @synchronized(self) {
        if (block == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Block is not allowed to be nil!"];
        }
        wilddogHandle wilddogHandle = self.currentHandle++;
        NSNumber *numberHandle = [NSNumber numberWithUnsignedInteger:wilddogHandle];
        [self.readyObservers setObject:[block copy] forKey:numberHandle];
        if (self.queries == nil) {
            [self updateQueries];
        }
        if (self.outstandingQueries.count == 0) {
            dispatch_async(self.geoFire.callbackQueue, block);
        }
        return wilddogHandle;
    }
}

@end
