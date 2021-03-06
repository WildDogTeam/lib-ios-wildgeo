
//
//  GWRegionQuery.h
//  WildGeo
//
//  Created by Jonny Dimond on 7/11/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface GWRegionQuery : GWQuery

/**
 * The region to search for this query. Update this value to update the query. Events are triggered for any keys that
 * move in or out of the search area.
 */
@property (atomic, readwrite) MKCoordinateRegion region;

@end
