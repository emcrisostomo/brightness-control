//
//  BSAppDelegate.m
//  brightness-setter
//
//  Created by Enrico Maria Crisostomo on 19/04/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BSAppDelegate.h"

@implementation BSAppDelegate

void handleUncaughtException(NSException * e)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Error"];
    [alert setInformativeText:[e reason]];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];

    [NSApp terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSSetUncaughtExceptionHandler(handleUncaughtException);
    
    @try {
        [self loadIOServices];
        [self createDockIcon];
        lastBrightnessValue = [self getCurrentBrightness];
    }
    @catch (NSException * e)
    {
        handleUncaughtException(e);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [pollTimer invalidate];
    [[NSStatusBar systemStatusBar] removeStatusItem:item];
    [self releaseIOServices];
}

- (void)pollTimerFired:(NSTimer *)timer
{
    float currentValue = [self getCurrentBrightness];
    
    if (lastBrightnessValue == currentValue) return;
    
    lastBrightnessValue = currentValue;
    
    NSLog(@"Brightness change detected: %f.", lastBrightnessValue);
    
    [_brightnessSlider setFloatValue:lastBrightnessValue * 100];
}

- (void)loadIOServices
{
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &service_iterator);
    
    if (result != kIOReturnSuccess)
    {
        NSLog(@"IOServiceGetMatchingServices failed.");
        [NSException raise:@"IOServiceGetMatchingServices failed."
                    format:@"IOServiceGetMatchingServices failed."];
    }
}

- (void)releaseIOServices
{
    IOIteratorReset(service_iterator);
    
    io_object_t service;
    while ((service = IOIteratorNext(service_iterator)))
    {
        IOObjectRelease(service);
    }
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
    IOIteratorReset(service_iterator);
    
    io_object_t service;
    float currentValue;
    while ((service = IOIteratorNext(service_iterator))) {
        IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &currentValue);

        return currentValue;
    }
    
    NSLog(@"Brightness cannot be obtained.");
    
    return .5;
}

- (void)setBrightness:(float)brightness
{
    if (lastBrightnessValue == brightness) return;
    else lastBrightnessValue = brightness;
    
    NSLog(@"%f", brightness);
    
    IOIteratorReset(service_iterator);

    io_object_t service;
    while ((service = IOIteratorNext(service_iterator)))
    {
        IODisplaySetFloatParameter(service,
                                   kNilOptions,
                                   CFSTR(kIODisplayBrightnessKey),
                                   brightness);
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
    
    pollTimer = [NSTimer timerWithTimeInterval:(1.0 / 10.0)
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
