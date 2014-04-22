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

- (id)init
{
    self = [super init];
    if (self)
    {
        _saveBrightnessController = [[BSSaveBrightnessWindowController alloc] initWithWindowNibName:@"BSSaveBrightnessWindowController"];

        __weak typeof(self) weakSelf = self;
        _saveBrightnessController.closeCallback = ^( bool saved )
        {
            [weakSelf saveBrightness:saved];
        };
    }
    
    return self;
}

- (void)dealloc
{
    _saveBrightnessController = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSSetUncaughtExceptionHandler(handleUncaughtException);
    [self setDefaults];
    [self getDefaults];
    
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
    
    NSLog(@"Brightness change detected outside the application: %f.", lastBrightnessValue);

    [_brightnessSlider setFloatValue:currentValue * 100];
    [self setBrightness:currentValue];
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

- (void)getDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float f = [defaults floatForKey:kBSBrightnessPropertyName];
    NSLog(@"Value read: %f", f);
}

- (void)setDefaults
{
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
    [defaults setObject:[NSNumber numberWithFloat:-1]
                forKey:kBSBrightnessPropertyName];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // setting defaults in shared controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
}

- (float)getCurrentBrightness
{
    IOIteratorReset(service_iterator);
    
    io_object_t service;
    float currentValue;
    while ((service = IOIteratorNext(service_iterator)))
    {
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

    [self.RestoreMenuItem setEnabled:[self isRestoreEnabled]];
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

- (IBAction)saveCurrentBrightness:(id)sender
{
    float brightness = [self getCurrentBrightness];
    [_saveBrightnessController reset];
    [_saveBrightnessController setBrightness:brightness];
    
    NSAssert(modalSession == nil, @"modalSession should be null.");
    modalSession = [NSApp beginModalSessionForWindow:[_saveBrightnessController window]];
    [NSApp runModalSession:modalSession];
    
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) askRestoreDone:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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
    // This is apparently needed otherwise the blue highlighting in the dock
    // menu would not go away.
    const float savedBrightness = [self getSavedBrightnessValue];
    NSAlert *restoreDialog = [[NSAlert alloc]init];
    [restoreDialog setMessageText:[NSString stringWithFormat:@"Are you sure you want to restore brightness to %f?", savedBrightness]];
    [restoreDialog addButtonWithTitle:@"Ok"];
    [restoreDialog addButtonWithTitle:@"Cancel"];
    [restoreDialog beginSheetModalForWindow:nil
                              modalDelegate:self
                             didEndSelector:@selector(askRestoreDone:returnCode:contextInfo:)
                                contextInfo:nil];
}

- (void)saveBrightness:(bool)saved
{
    @try
    {
        if(!saved) return;
        
        // TODO: save value
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithFloat:[_saveBrightnessController brightness]]
                     forKey:kBSBrightnessPropertyName];

        NSLog(@"Setting name: %@", [_saveBrightnessController settingName]);
    }
    @finally
    {
        [NSApp endModalSession:modalSession];
        modalSession = nil;
    }
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    SEL act = [anItem action];
    
    if (act == @selector(restoreBrightness:))
    {
        return [self isRestoreEnabled];
    }
    
    return YES;
}

- (BOOL)isRestoreEnabled
{
    const float savedBrightness = [self getSavedBrightnessValue];
    return savedBrightness != lastBrightnessValue && savedBrightness >= 0 && savedBrightness <= 1;
}

- (float)getSavedBrightnessValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:kBSBrightnessPropertyName];
}

@end
