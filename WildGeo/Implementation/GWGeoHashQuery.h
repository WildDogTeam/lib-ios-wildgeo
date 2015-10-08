//
//  GWGeoHashQuery.h
//  WildGeo
//
//  Created by Jonny Dimond on 7/7/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "GWGeoHash.h"

@interface GWGeoHashQuery : NSObject<NSCopying>

@property (nonatomic, strong, readonly) NSString *startValue;
@property (nonatomic, strong, readonly) NSString *endValue;

+ (NSSet *)queriesForLocation:(CLLocationCoordinate2D)location radius:(double)radius;
+ (NSSet *)queriesForRegion:(MKCoordinateRegion)region;

- (BOOL)containsGeoHash:(GWGeoHash *)hash;

- (BOOL)canJoinWith:(GWGeoHashQuery *)other;
- (GWGeoHashQuery *)joinWith:(GWGeoHashQuery *)other;

@end
