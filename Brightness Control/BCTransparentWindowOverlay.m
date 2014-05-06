/*
 * BCTransparentWindowOverlay.m
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

#import "BCTransparentWindowOverlay.h"

@implementation BCTransparentWindowOverlay
{
    float _alpha;
    BOOL _visible;
    NSArray *overlayWindows;
}

+ (instancetype)transparentWindowOverlay
{
    return [[BCTransparentWindowOverlay alloc] init];
}

- (void)setAlpha:(float)alpha
{
    _alpha = alpha;
    [self updateOverlay];
}

- (float)alpha
{
    return _alpha;
}

- (BOOL)visible
{
    return _visible;
}

- (void)setVisible:(BOOL)visible
{
    if (!(visible ^ _visible))
    {
        return;
    }
    
    _visible = visible;
    
    if (_visible)
    {
        [self createOverlayWindows];
    }
    else
    {
        [self destroyOverlayWindows];
    }
}

- (void)destroyOverlayWindows
{
    for (id wnd in overlayWindows)
    {
        [wnd orderOut:nil];
    }
    
    overlayWindows = [[NSMutableArray alloc] init];
}

- (void)createOverlayWindows
{
    [self destroyOverlayWindows];
    
    if (!_visible) {
        return;
    }
    
    NSMutableArray *overlays = [[NSMutableArray alloc] init];
    
    for (id screen in [NSScreen screens])
    {
        NSWindow *wnd = [[NSWindow alloc] initWithContentRect:[screen frame]
                                                    styleMask:NSBorderlessWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:YES];
        
        [wnd setOpaque:NO];
        [wnd setHasShadow:NO];
        [wnd setBackgroundColor:[NSColor blackColor]];
        [wnd setLevel:NSScreenSaverWindowLevel];
        [wnd setIgnoresMouseEvents:YES];
        NSUInteger collectionBehaviour;
        collectionBehaviour = [wnd collectionBehavior];
        collectionBehaviour |= NSWindowCollectionBehaviorCanJoinAllSpaces;
        [wnd setCollectionBehavior:collectionBehaviour];
        
        [overlays addObject:wnd];
    }
    
    overlayWindows = overlays;
    
    [self updateOverlay];
    
    for (id wnd in overlayWindows)
    {
        [wnd orderFront:nil];
    }
}

- (void)updateOverlay
{
    [self setOverlayAlpha:[self alpha]];
}

- (void)setOverlayAlpha:(float)brightness
{
    NSLog(@"Setting overlay brightness: %f.", brightness);
    
    float adjustedValue = brightness;

    // Mapping b=[0, 1] to b_a=[1, 2] and then calculating the brightness as
    // log_2(b_a).
    if ([self logarithmicScale])
    {
        adjustedValue += 1;
        adjustedValue = log2f(adjustedValue);
        NSLog(@"Setting overlay brightness adjusted: %f.", adjustedValue);
    }
    
    for (id wnd in overlayWindows)
    {
        [wnd setAlphaValue:adjustedValue];
    }
}

@end
