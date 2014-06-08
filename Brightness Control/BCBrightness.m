//
//  BCBrightness.m
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 07/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BCBrightness.h"

@implementation BCBrightness

- (BOOL)isEqual:(id)other
{
    if (self == other)
        return YES;
    if (other == nil || ![other isKindOfClass:[self class]])
        return NO;
    
    return [self isEqualToBrightness:other];
}

- (BOOL)isEqualToBrightness:(BCBrightness *)brightness
{
    if (self == brightness)
        return YES;
    
    return [[self name] isEqualToString:[brightness name]];
}
@end
