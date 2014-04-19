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
    [self createDockIcon];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    [bar removeStatusItem:item];
}

- (void) createDockIcon
{
    if (item != nil)
    {
        NSLog(@"Dock icon already set");
        return;
    }
    
    // set the slider to the current value
    float currentValue = [self getCurrentBrightness] * 100;
    NSLog(@"Current brightness %f.", currentValue);
    
    [_brightnessSlider setFloatValue:currentValue];
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    item = [bar statusItemWithLength:NSSquareStatusItemLength];
    [item setImage:[NSImage imageNamed:@"bs.png"]];
    [item setHighlightMode:YES];
    [item setEnabled:TRUE];
    [item setToolTip:@"Brightness Setter"];
    [item setMenu:_dockMenu];
}

- (float)getCurrentBrightness
{
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    
    // If we were successful
    if (result == kIOReturnSuccess)
    {
        io_object_t service;
        float currentValue;
        while ((service = IOIteratorNext(iterator))) {
            IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &currentValue);
            // Let the object go
            IOObjectRelease(service);
            
            return currentValue;
        }
    }

    return .5;
}

- (IBAction)updateValue:(id)sender {
    NSLog(@"%f", [sender doubleValue]);
    
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    
    // If we were successful
    if (result == kIOReturnSuccess)
    {
        io_object_t service;
        while ((service = IOIteratorNext(iterator))) {
            IODisplaySetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), [sender doubleValue]/100);
            
            // Let the object go
            IOObjectRelease(service);
        }
    }
}

@end
