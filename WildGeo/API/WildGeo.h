/*
 * wilddog WildGeo iOS Library
 *
 * Copyright © 2014 wilddog - All Rights Reserved
 * https://www.wilddog.com
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binaryform must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY WILDDOG AS IS AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL wilddog BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "GWQuery.h"
#import "GWCircleQuery.h"
#import "GWRegionQuery.h"

@class Wilddog;

typedef void (^GFCompletionBlock) (NSError *error);
typedef void (^GFCallbackBlock) (CLLocation *location, NSError *error);

/**
 * A WildGeo instance is used to store geo location data at a wilddog location.
 */
@interface WildGeo : NSObject

/**
 * The wilddog reference this WildGeo instance uses.
 */
@property (nonatomic, strong, readonly) Wilddog *wilddogRef;

/**
 * The dispatch queue this WildGeo object and all its GFQueries use for callbacks.
 */
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

/** @name Creating new WildGeo objects */

/**
 * Initializes a new WildGeo instance at the given wilddog location.
 * @param wilddog The wilddog location to attach this WildGeo instance to
 * @return The new WildGeo instance
 */
- (id)initWithWilddogRef:(Wilddog *)wilddog;

/** @name Setting and Updating Locations */

/**
 * Updates the location for a key.
 * @param location The location as a geographic coordinate
 * @param key The key for which this location is saved
 */
- (void)setLocation:(CLLocation *)location
             forKey:(NSString *)key;

/**
 * Updates the location for a key and calls the completion callback once the location was successfully updated on the
 * server.
 * @param location The location as a geographic coordinate
 * @param key The key for which this location is saved
 * @param block The completion block that is called once the location was successfully updated on the server
 */
- (void)setLocation:(CLLocation *)location
             forKey:(NSString *)key
withCompletionBlock:(GFCompletionBlock)block;

/**
 * Removes the location for a given key.
 * @param key The key for which the location is removed
 */
- (void)removeKey:(NSString *)key;

/**
 * Removes the location for a given key and calls the completion callback once the location was successfully updated on
 * the server.
 * @param key The key for which the location is removed
 * @param block The completion block that is called once the location was successfully updated on the server
 */
- (void)removeKey:(NSString *)key withCompletionBlock:(GFCompletionBlock)block;

/**
 * Gets the current location for a key in WildGeo and calls the callback with the location or nil if there is no
 * location for the key in WildGeo. If an error occurred, the callback will be called with the error and location
 * will be nil.
 *
 * @param key The key to observe the location for
 * @param callback The callback that is called for the current location
 * @return
 */
- (void)getLocationForKey:(NSString *)key
             withCallback:(GFCallbackBlock)callback;

/**
 * Creates a new WildGeo query centered at a given location with a given radius. The GWQuery object can be used to query
 * keys that enter, move, and exit the search radius.
 * @param location The location at which the query is centered
 * @param radius The radius in kilometers of the geo query
 * @return The GWCircleQuery object that can be used for geo queries.
 */
- (GWCircleQuery *)queryAtLocation:(CLLocation *)location
                        withRadius:(double)radius;

/**
 * Creates a new WildGeo query for a given region. The GWQuery object can be used to query
 * keys that enter, move, and exit the search region.
 * @param region The region which this query searches
 * @return The GWRegionQuery object that can be used for geo queries.
 */
- (GWRegionQuery *)queryWithRegion:(MKCoordinateRegion)region;

@end
