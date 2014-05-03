/*
 * LoginItem.m
 * Brightness Control
 *
 * Copyright (C) 2014, Enrico M. Crisostomo
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "LoginItem.h"

@implementation LoginItem

CFURLRef url;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        [self initHelper:appPath];
    }
    
    return self;
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    if (!bundle)
    {
        NSException* nullException = [NSException
                                     exceptionWithName:@"NullPointerException"
                                     reason:@"Bundle cannot be null."
                                     userInfo:nil];
        @throw nullException;
    }
    
    self = [super init];
    
    if (self)
    {
        NSString * appPath = [bundle bundlePath];
        [self initHelper:appPath];
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString *)appPath
{
    if (!appPath)
    {
        NSException* nullException = [NSException
                                      exceptionWithName:@"NullPointerException"
                                      reason:@"Path cannot be null."
                                      userInfo:nil];
        @throw nullException;
    }
    
    self = [super init];
    
    if (self)
    {
        [self initHelper:appPath];
    }
    
    return self;
}

- (void)initHelper:(NSString *)appPath
{
    url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
}

+ (instancetype)loginItem
{
    return [[LoginItem alloc] initWithBundle:[NSBundle mainBundle]];
}

+ (instancetype)loginItemWithBundle:(NSBundle *)bundle
{
    return [[LoginItem alloc] initWithBundle:bundle];
}

+ (instancetype)loginItemWithPath:(NSString *)path
{
    return [[LoginItem alloc] initWithPath:path];
}

- (BOOL)isLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    
    if (loginItems)
    {
        UInt32 seed;
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seed);
        
        for (id item in (__bridge NSArray *)loginItemsArray)
        {
            LSSharedFileListItemRef loginItem = (__bridge LSSharedFileListItemRef)item;
            CFURLRef itemUrl;
            
            if (LSSharedFileListItemResolve(loginItem, 0, &itemUrl, NULL) == noErr)
            {
                if (CFEqual(itemUrl, url))
                {
                    return YES;
                }
            }
            else
            {
                NSLog(@"Error: LSSharedFileListItemResolve failed.");
            }
        }
    }
    else
    {
        NSLog(@"Warning: LSSharedFileListCreate failed, could not get list of login items.");
    }
    
    return NO;
}

- (void)addLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    
    if (!loginItems)
    {
        NSLog(@"Error: LSSharedFileListCreate failed, could not get list of login items.");
        return;
    }
    
    if(!LSSharedFileListInsertItemURL(loginItems,
                                      kLSSharedFileListItemLast,
                                      NULL,
                                      NULL,
                                      url,
                                      NULL,
                                      NULL))
    {
        NSLog(@"Error: LSSharedFileListInsertItemURL failed, could not create login item.");
    }
}

- (void)removeLoginItem
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    if (loginItems)
    {
        BOOL removed = NO;
        UInt32 seed;
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seed);
        
        for (id item in (__bridge NSArray *)loginItemsArray)
        {
            LSSharedFileListItemRef loginItem = (__bridge LSSharedFileListItemRef)item;
            CFURLRef itemUrl;
            
            if (LSSharedFileListItemResolve(loginItem, 0, &itemUrl, NULL) == noErr)
            {
                if (CFEqual(itemUrl, url))
                {
                    if (LSSharedFileListItemRemove(loginItems, loginItem) == noErr)
                    {
                        removed = YES;
                        break;
                    }
                    else
                    {
                        NSLog(@"Error: Unknown error while removing login item.");
                    }
                }
            }
        }
        
        if (!removed)
        {
            NSLog(@"Error: could not find login item to remove.");
        }
    }
    else
    {
        NSLog(@"Warning: could not get list of login items.");
    }
}

@end
