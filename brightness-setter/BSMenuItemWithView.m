//
//  BSMenuItemWithView.m
//  brightness-setter
//
//  Created by Enrico Maria Crisostomo on 20/04/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BSMenuItemWithView.h"

@implementation BSMenuItemWithView

- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    
    id customView = [self view];
    if ([customView respondsToSelector:@selector(setEnabled:)])
    {
        [customView setEnabled:flag];
    }
}

@end
