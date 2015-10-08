//
//  WilddogGeo+Private.h
//  WilddogGeo
//
//  Created by Jonny Dimond on 7/7/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import "WilddogGeo.h"
#import <CoreLocation/CoreLocation.h>

@interface WilddogGeo (Private)

- (Wilddog *)wilddogRefForLocationKey:(NSString *)key;

+ (CLLocation *)locationFromValue:(id)dict;
+ (NSDictionary *)dictFromLocation:(CLLocation *)location;

@end
