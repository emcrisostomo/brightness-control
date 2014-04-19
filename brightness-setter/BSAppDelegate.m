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
    lastBrightnessValue = [self getCurrentBrightness];
}

- (void)pollTimerFired:(NSTimer *)timer
{
    float currentValue = [self getCurrentBrightness];
    
    if (lastBrightnessValue == currentValue) return;
    
    lastBrightnessValue = currentValue;
    
    NSLog(@"Brightness change detected: %f.", lastBrightnessValue);
    
    [_brightnessSlider setFloatValue:currentValue * 100];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [pollTimer invalidate];
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

    NSLog(@"Brightness cannot be obtained.");
    
    return .5;
}

- (void)setBrightness:(float)brightness
{
    if (lastBrightnessValue == brightness) return;
    else lastBrightnessValue = brightness;
    
    NSLog(@"%f", brightness);
    
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    
    // If we were successful
    if (result == kIOReturnSuccess)
    {
        io_object_t service;
        while ((service = IOIteratorNext(iterator)))
        {
            IODisplaySetFloatParameter(service,
                                       kNilOptions,
                                       CFSTR(kIODisplayBrightnessKey),
                                       brightness);
            
            // Let the object go
            IOObjectRelease(service);
        }
    }
}

- (IBAction)updateValue:(id)sender
{
    [self setBrightness:[sender floatValue]/100];
}

- (void)schedulePollTimer
{
    if (pollTimer != nil)
    {
        NSLog(@"Warning: Poll timer was not null: invalidating it.");
        [pollTimer invalidate];
    }
    
    pollTimer = [NSTimer timerWithTimeInterval:(1.0 / 5.0)
                                        target:self
                                      selector:@selector(pollTimerFired:)
                                      userInfo:nil
                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:pollTimer forMode:NSRunLoopCommonModes];
}

- (void)invalidatePollTimer
{
    [pollTimer invalidate];
    pollTimer = nil;
}

- (void)menuWillOpen:(NSMenu *) menu
{
    if (menu != _dockMenu) return;
    
    // set the slider to the current value
    float currentValue = [self getCurrentBrightness];
    
    NSLog(@"Current brightness %f.", currentValue);
    
    lastBrightnessValue = currentValue;
    [_brightnessSlider setFloatValue:currentValue * 100];

    [self schedulePollTimer];
}

- (void)menuDidClose:(NSMenu *)menu
{
    [self invalidatePollTimer];
}

@end
