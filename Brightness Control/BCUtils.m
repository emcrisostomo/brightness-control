//
//  BCUtils.m
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 07/05/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BCUtils.h"

@implementation BCUtils

- (instancetype)init
{
    NSException* exception = [NSException
                              exceptionWithName:@"UnsupportedOperationException"
                              reason:@"This class cannot be instantiated."
                              userInfo:nil];
    @throw exception;
}

+ (BOOL)isBrightnessValid:(float)brightness
{
    return brightness >= 0 && brightness <= 1;
}

@end
