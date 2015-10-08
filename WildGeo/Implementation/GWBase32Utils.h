//
//  GWBase32Utils.h
//  WildGeo
//
//  Created by Jonny Dimond on 7/7/14.
//  Copyright (c) 2014 wilddog. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BITS_PER_BASE32_CHAR 5

@interface GWBase32Utils : NSObject

+ (char)valueToBase32Character:(NSUInteger)value;
+ (NSUInteger)base32CharacterToValue:(char)character;

+ (NSString *)base32Characters;

@end
