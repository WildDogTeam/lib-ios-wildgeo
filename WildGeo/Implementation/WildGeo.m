//
//  WildGeo.m
//  WildGeo
//
//  Created by Jonny Dimond on 7/3/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import "WildGeo.h"
#import "WildGeo+Private.h"
#import "GWGeoHash.h"
#import "GWQuery+Private.h"
#import <WilddogSync/WilddogSync.h>

NSString * const kWildGeoErrorDomain = @"com.wilddog.geowild";

enum {
    GFParseError = 1000
};

@interface WildGeo ()

@property (nonatomic, strong, readwrite) Wilddog *wilddogRef;

@end

@implementation WildGeo

- (id)init
{
    [NSException raise:NSGenericException
                format:@"init is not supported. Please use %@ instead",
     NSStringFromSelector(@selector(initWithWilddogRef:))];
    return nil;
}

- (id)initWithWilddogRef:(Wilddog *)wilddogRef
{
    self = [super init];
    if (self != nil) {
        if (wilddogRef == nil) {
            [NSException raise:NSInvalidArgumentException format:@"wilddog was nil!"];
        }
        self.wilddogRef = wilddogRef;
        self.callbackQueue = dispatch_get_main_queue();
    }
    return self;
}

- (void)setLocation:(CLLocation *)location forKey:(NSString *)key
{
    [self setLocation:location forKey:key withCompletionBlock:nil];
}

- (void)setLocation:(CLLocation *)location
             forKey:(NSString *)key
withCompletionBlock:(GFCompletionBlock)block
{
    if (!CLLocationCoordinate2DIsValid(location.coordinate)) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Not a valid coordinate: [%f, %f]",
         location.coordinate.latitude, location.coordinate.longitude];
    }
    [self setLocationValue:location
                    forKey:key
                 withBlock:block];
}

- (Wilddog *)wilddogRefForLocationKey:(NSString *)key
{
    static NSCharacterSet *illegalCharacters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@".#$][/"];
    });
    if ([key rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Not a valid WildGeo key: \"%@\". Characters .#$][/ not allowed in key!", key];
    }
    return [self.wilddogRef childByAppendingPath:key];
}

- (void)setLocationValue:(CLLocation *)location
                  forKey:(NSString *)key
               withBlock:(GFCompletionBlock)block
{
    NSDictionary *value;
    NSString *priority;
    if (location != nil) {
        NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
        NSNumber *lng = [NSNumber numberWithDouble:location.coordinate.longitude];
        NSString *geoHash = [GWGeoHash newWithLocation:location.coordinate].geoHashValue;
        value = @{ @"l": @[ lat, lng ], @"g": geoHash };
        priority = geoHash;
    } else {
        value = nil;
        priority = nil;
    }
    [[self wilddogRefForLocationKey:key] setValue:value
                                       andPriority:priority
                               withCompletionBlock:^(NSError *error, Wilddog *ref) {
        if (block != nil) {
            dispatch_async(self.callbackQueue, ^{
                block(error);
            });
        }
    }];
}

- (void)removeKey:(NSString *)key
{
    [self removeKey:key withCompletionBlock:nil];
}

- (void)removeKey:(NSString *)key withCompletionBlock:(GFCompletionBlock)block
{
    [self setLocationValue:nil forKey:key withBlock:block];
}

+ (CLLocation *)locationFromValue:(id)value
{
    if ([value isKindOfClass:[NSDictionary class]] && [value objectForKey:@"l"] != nil) {
        id locObj = [value objectForKey:@"l"];
        if ([locObj isKindOfClass:[NSArray class]] && [locObj count] == 2) {
            id latNum = [locObj objectAtIndex:0];
            id lngNum = [locObj objectAtIndex:1];
            if ([latNum isKindOfClass:[NSNumber class]] &&
                [lngNum isKindOfClass:[NSNumber class]]) {
                CLLocationDegrees lat = [latNum doubleValue];
                CLLocationDegrees lng = [lngNum doubleValue];
                if (CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(lat, lng))) {
                    return [[CLLocation alloc] initWithLatitude:lat longitude:lng];
                }
            }
        }
    }
    return nil;
}

- (void)getLocationForKey:(NSString *)key withCallback:(GFCallbackBlock)callback
{
    [[self wilddogRefForLocationKey:key]
     observeSingleEventOfType:WEventTypeValue
     withBlock:^(WDataSnapshot *snapshot) {
         dispatch_async(self.callbackQueue, ^{
             if (snapshot.value == nil || [snapshot.value isMemberOfClass:[NSNull class]]) {
                 callback(nil, nil);
             } else {
                 CLLocation *location = [WildGeo locationFromValue:snapshot.value];
                 if (location != nil) {
                     callback(location, nil);
                 } else {
                     NSMutableDictionary* details = [NSMutableDictionary dictionary];
                     [details setValue:[NSString stringWithFormat:@"Unable to parse location value: %@", snapshot.value]
                                forKey:NSLocalizedDescriptionKey];
                     NSError *error = [NSError errorWithDomain:kWildGeoErrorDomain code:GFParseError userInfo:details];
                     callback(nil, error);
                 }
             }
         });
     } withCancelBlock:^(NSError *error) {
         dispatch_async(self.callbackQueue, ^{
             callback(nil, error);
         });
     }];
}

- (GWCircleQuery *)queryAtLocation:(CLLocation *)location withRadius:(double)radius
{
    return [[GWCircleQuery alloc] initWithWildGeo:self location:location radius:radius];
}

- (GWRegionQuery *)queryWithRegion:(MKCoordinateRegion)region
{
    return [[GWRegionQuery alloc] initWithWildGeo:self region:region];
}

@end
