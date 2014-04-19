//
//  BSAppDelegate.m
//  brightness-setter
//
//  Created by Enrico Maria Crisostomo on 19/04/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BSAppDelegate.h"

@implementation BSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    item = [bar statusItemWithLength:NSSquareStatusItemLength];
    
    [item setImage:[NSImage imageNamed:@"bs.png"]];
    [item setHighlightMode:YES];
    [item setEnabled:TRUE];
    [item setToolTip:@"Brightness Setter"];
    [item setMenu:_dockMenu];
}

@end
