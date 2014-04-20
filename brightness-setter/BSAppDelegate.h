//
//  BSAppDelegate.h
//  brightness-setter
//
//  Created by Enrico Maria Crisostomo on 19/04/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BSSaveBrightnessWindowController.h"

@interface BSAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate> {
    NSStatusItem *item;
    float lastBrightnessValue;
    NSTimer *pollTimer;
    io_iterator_t service_iterator;
}

- (IBAction)updateValue:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *dockMenu;
@property (weak) IBOutlet NSSlider *brightnessSlider;
@property (strong, nonatomic) BSSaveBrightnessWindowController *saveBrightnessController;

@end
