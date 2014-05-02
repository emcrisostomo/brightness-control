/*
 * BSAppDelegate.m
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

#import "BSAppDelegate.h"

NSString * const kBSBrightnessPropertyName = @"com.blogspot.thegreyblog.brightness-setter.brightness";
NSString * const kBSPercentageShownPropertyName = @"com.blogspot.thegreyblog.brightness-setter.percentageShown";
const float kBSBrightnessTolerance = .01;

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

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
    NSLog(@"Screen configuration has changed");
    [self releaseIOServices];
    [self loadIOServices];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSSetUncaughtExceptionHandler(handleUncaughtException);
    
    @try
    {
        // Make sure slider view will be as wide as the contextual menu.
        [[self sliderView] setAutoresizingMask:NSViewWidthSizable];
        
        [self schedulePollTimer];
        [self scheduleStatusItemTimer];
        [self registerObservers];
        [self setDefaults];
        [self getDefaults];
        [self loadIOServices];
        [self createDockIcon];
        [self setBrightness:[self getCurrentBrightness]];
    }
    @catch (NSException * e)
    {
        handleUncaughtException(e);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self invalidateStatusItemTimer];
    [self invalidatePollTimer];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [self releaseIOServices];
}

- (void)registerObservers
{
    [self addObserver:self
           forKeyPath:@"percentageShown"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"brightness"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"restoreEnabled"
              options:NSKeyValueObservingOptionNew
              context:nil];
}

- (void)onUpdateBrightness
{
    [self updateStatusIcon];
    [self updateSliderValue];
    [self setRestoreEnabled:[self isRestoreEnabled]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void*)context
{
    if ([keyPath isEqualToString:@"percentageShown"])
    {
        [self updateStatusIcon];
    }
    
    if ([keyPath isEqualToString:@"brightness"])
    {
        [self onUpdateBrightness];
    }
    
    if ([keyPath isEqualToString:@"restoreEnabled"])
    {
        [self updateStatusIcon];
    }
}

- (void)updateSliderAndSetBrightness:(NSNumber *)updatedBrightness
{
    [self setBrightness:[updatedBrightness floatValue]];
}

- (void)statusItemTimerFired:(NSTimer *)timer
{
    if (![self isRestoreEnabled]) return;
    
    NSDate *now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSince1970];
    
    if (((int)time) % 2)
    {
        [statusItem setImage:[NSImage imageNamed:@"bulb.png"]];
    }
    else
    {
        [self updateStatusIcon];
    }
}

- (void)pollTimerFired:(NSTimer *)timer
{
    float currentValue = [self getCurrentBrightness];
    
    if (_brightness == currentValue) return;
    
    NSLog(@"External brightness change detected: %f.", currentValue);
    
    [self performSelectorOnMainThread:@selector(updateSliderAndSetBrightness:)
                           withObject:[NSNumber numberWithFloat:currentValue]
                        waitUntilDone:NO];
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

- (void)createDockIcon
{
    if (statusItem != nil)
    {
        NSLog(@"Dock icon already set. This method should not be called twice.");
        return;
    }
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"bulb.png"]];
    [statusItem setHighlightMode:YES];
    [statusItem setEnabled:TRUE];
    [statusItem setToolTip:@"Brightness Setter"];
    [statusItem setMenu:_dockMenu];
}

- (void)getDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float f = [defaults floatForKey:kBSBrightnessPropertyName];
    NSLog(@"Currently saved brightness value: %f.", f);
    
    [self setPercentageShown:[defaults boolForKey:kBSPercentageShownPropertyName]];
}

- (void)setDefaults
{
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
    defaults[kBSBrightnessPropertyName] = @(-1.0f);
    defaults[kBSPercentageShownPropertyName] = @(NO);
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // setting defaults in shared controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
}

- (float)getCurrentBrightness
{
    IOIteratorReset(service_iterator);
    
    io_object_t service;
    float currentValue = .5;
    
    NSMutableArray *brightnessValues = [[NSMutableArray alloc] init];
    
    while ((service = IOIteratorNext(service_iterator)))
    {
        IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &currentValue);
        [brightnessValues addObject:[NSNumber numberWithFloat:currentValue]];
    }
    
    if ([brightnessValues count] > 0)
    {
        currentValue = [[brightnessValues objectAtIndex:0] floatValue];
    }
    
    // Check that all brightness values are within a (completely arbitrary) 1%
    // tolerance between each other.  AFAIK, the UI of OS X does not let you
    // independently set a brightness value for each monitor, but maybe some
    // appliance software (such as monitor calibrators) would.
    for (unsigned int i=0; i < [brightnessValues count]; ++i)
    {
        const float currentMonitorBrightness = [[brightnessValues objectAtIndex:i] floatValue];
        
        for (unsigned int j=i + 1; j < [brightnessValues count]; ++j)
        {
            if (fabs([[brightnessValues objectAtIndex:j] floatValue] - currentMonitorBrightness) > kBSBrightnessTolerance)
            {
                NSString *msg = [NSString stringWithFormat:@"%lu services satisfying filter [IODisplayConnect] were found whose brightness values are not within the specified tolerance.", (unsigned long)[brightnessValues count]];
                NSLog(@"%lu services satisfying filter [IODisplayConnect] were found whose brightness values are not within the specified tolerance.", (unsigned long)[brightnessValues count]);
                [NSException raise:msg
                            format:@"%lu services satisfying filter [IODisplayConnect] were found whose brightness values are not within the specified tolerance.", (unsigned long)[brightnessValues count]];
            }
        }
    }
    
    return currentValue;
}

- (float)brightness
{
    return _brightness;
}

- (void)setBrightness:(float)brightness
{
    if ([self brightness] == brightness) return;
    
    _brightness = brightness;
    
    NSLog(@"Setting brightness value: %f.", brightness);
    
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

- (void)updateStatusIcon
{
    if ([self percentageShown])
    {
        [statusItem setTitle:[NSString stringWithFormat:@"%.3f", _brightness]];
    }
    else
    {
        [statusItem setTitle:nil];
    }
    
    const float savedBrightness = [self getSavedBrightnessValue];

    if (![self isSavedBrightnessValid:savedBrightness])
    {
        [statusItem setImage:[NSImage imageNamed:@"bulb.png"]];
    }
    else if ([self isRestoreEnabled])
    {
        [statusItem setImage:[NSImage imageNamed:@"yellow_bulb.png"]];
    }
    else
    {
        [statusItem setImage:[NSImage imageNamed:@"green_bulb.png"]];
    }
}

- (void)updateSliderValue
{
    [self setSliderValue:([self brightness] * 100)];
}

- (BOOL)restoreEnabled
{
    return [self isRestoreEnabled];
}

- (void)setRestoreEnabled:(BOOL)restoreEnabled
{
    // No-op, used only to trigger KVO notifications.
}

- (IBAction)updateValue:(id)sender
{
    [self setBrightness:[sender floatValue]/100];
}

- (void)scheduleStatusItemTimer
{
    if (statusItemTimer != nil)
    {
        NSLog(@"Warning: Status item timer was not null: invalidating it. This may be a bug.");
        [statusItemTimer invalidate];
    }
    
    statusItemTimer = [NSTimer timerWithTimeInterval:(1.0)
                                        target:self
                                      selector:@selector(statusItemTimerFired:)
                                      userInfo:nil
                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:statusItemTimer forMode:NSRunLoopCommonModes];
}

- (void)invalidateStatusItemTimer
{
    [statusItemTimer invalidate];
    statusItemTimer = nil;
}

- (void)schedulePollTimer
{
    if (pollTimer != nil)
    {
        NSLog(@"Warning: Poll timer was not null: invalidating it. This may be a bug.");
        [pollTimer invalidate];
    }
    
    pollTimer = [NSTimer timerWithTimeInterval:(1.0 / 2.0)
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

- (IBAction)saveCurrentBrightness:(id)sender
{
    const float brightness = [self getCurrentBrightness];
    NSAlert *saveDialog = [[NSAlert alloc] init];
    [saveDialog setMessageText:[NSString stringWithFormat:@"Are you sure you want to save brightness value %f?", brightness]];
    [saveDialog addButtonWithTitle:@"Ok"];
    [saveDialog addButtonWithTitle:@"Cancel"];
    [saveDialog beginSheetModalForWindow:nil
                           modalDelegate:self
                          didEndSelector:@selector(askSaveDone:returnCode:contextInfo:)
                             contextInfo:(__bridge_retained void *)@(brightness)];
}

- (void)askSaveDone:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSNumber *brightness = (__bridge_transfer NSNumber *)contextInfo;
    
    switch(returnCode)
    {
        case NSAlertFirstButtonReturn:
            [self saveBrightness:[brightness floatValue]];
            [self setRestoreEnabled:[self isRestoreEnabled]];
            break;
    }
}

- (void)askRestoreDone:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    switch(returnCode)
    {
        case NSAlertFirstButtonReturn:
            [self setBrightness:[self getSavedBrightnessValue]];
            break;
    }
}

- (IBAction)restoreBrightness:(id)sender
{
    // beginSheetModalForWindow:nil is apparently needed
    // otherwise the blue highlighting in the dock
    // menu would not go away.
    const float savedBrightness = [self getSavedBrightnessValue];
    NSAlert *restoreDialog = [[NSAlert alloc] init];
    [restoreDialog setMessageText:[NSString stringWithFormat:@"Are you sure you want to restore brightness to %f?", savedBrightness]];
    [restoreDialog addButtonWithTitle:@"Ok"];
    [restoreDialog addButtonWithTitle:@"Cancel"];
    [restoreDialog beginSheetModalForWindow:nil
                              modalDelegate:self
                             didEndSelector:@selector(askRestoreDone:returnCode:contextInfo:)
                                contextInfo:nil];
}

- (IBAction)showPercentage:(id)sender
{
    BOOL newPercentageShown = ![self percentageShown];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(newPercentageShown)
                 forKey:kBSPercentageShownPropertyName];
    
    [self setPercentageShown:newPercentageShown];
}

- (void)saveBrightness:(float)brightness
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(brightness)
                 forKey:kBSBrightnessPropertyName];
    
    NSLog(@"Saved brightness: %f.", brightness);
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    SEL act = [anItem action];
    id obj = anItem;
    
    if (act == @selector(showPercentage:))
    {
        if ([obj respondsToSelector:@selector(setState:)])
        {
            [obj setState:([self percentageShown] ? NSOnState : NSOffState)];
        }
    }
    
    return YES;
}

- (BOOL)isRestoreEnabled
{
    const float savedBrightness = [self getSavedBrightnessValue];
    return savedBrightness != _brightness && [self isSavedBrightnessValid:savedBrightness];
}

- (float)getSavedBrightnessValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:kBSBrightnessPropertyName];
}

- (BOOL)isSavedBrightnessValid:(float)savedBrightness
{
    return savedBrightness >= 0 && savedBrightness <= 1;
}

@end
