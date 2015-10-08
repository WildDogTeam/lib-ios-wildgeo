//
//  GWQuery+Private.h
//  WilddogGeo
//
//  Created by Jonny Dimond on 7/3/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "GWQuery.h"
#import "GWRegionQuery.h"
#import "GWCircleQuery.h"

@class WilddogGeo;

@interface GWQuery (Private)

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire;
- (BOOL)locationIsInQuery:(CLLocation *)location;
- (void)searchCriteriaDidChange;
- (NSSet *)queriesForCurrentCriteria;

@end

@interface GWCircleQuery (Private)

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire
             location:(CLLocation *)location
               radius:(double)radius;

@end

@interface GWRegionQuery (Private)

- (id)initWithWilddogGeo:(WilddogGeo *)geoFire region:(MKCoordinateRegion)region;

@end
