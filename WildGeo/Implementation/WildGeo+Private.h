//
//  WildGeo+Private.h
//  WildGeo
//
//  Created by Jonny Dimond on 7/7/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import "WildGeo.h"
#import <CoreLocation/CoreLocation.h>

@interface WildGeo (Private)

- (WDGSyncReference *)wilddogRefForLocationKey:(NSString *)key;

+ (CLLocation *)locationFromValue:(id)dict;
+ (NSDictionary *)dictFromLocation:(CLLocation *)location;

@end
