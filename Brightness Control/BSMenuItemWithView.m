/*
 * BSMenuItemWithView.m
 * brightness-setter
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
    
    for (id subview in [[self view] subviews])
    {
        if ([subview respondsToSelector:@selector(setEnabled:)])
        {
            [subview setEnabled:flag];
        }
    }
}

@end