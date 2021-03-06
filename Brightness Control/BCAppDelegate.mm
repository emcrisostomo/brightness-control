/*
 * BSAppDelegate.m
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

#import "BCAppDelegate.h"
#import "BCUtils.h"
#import "EMCLoginItem/EMCLoginItem.h"
#import "BCTransparentWindowOverlay.h"
#import "BCBrightnessTableController.h"
#import "BCDisplay.hpp"

NSString * const kBSPercentageShownPropertyName = @"com.blogspot.thegreyblog.brightness-control.percentageShown";
NSString * const kBSUseOverlayPropertyName = @"com.blogspot.thegreyblog.brightness-control.useOverlay";
NSString * const kBSOverlayBelowMainMenuPropertyName = @"com.blogspot.thegreyblog.brightness-control.overlayBelowMainMenu";
NSString * const kBSSortDescriptorsPropertyName = @"com.blogspot.thegreyblog.brightness-control.sortDescriptors";
NSString * const kBSActiveProfilePropertyName = @"com.blogspot.thegreyblog.brightness-control.activeProfile";

@interface BCAppDelegate ()

@property (unsafe_unretained) IBOutlet NSWindow *saveWindow;
@property (weak) IBOutlet BCBrightnessTableController *brightnessTableController;
@property (weak) IBOutlet NSMenuItem *profileMenuItem;
@property NSString *activeProfile;

@end

@implementation BCAppDelegate
{
    EMCLoginItem *loginItem;
    NSStatusItem *statusItem;
    float _brightness;
    NSTimer *pollTimer;
    NSTimer *statusItemTimer;
    io_iterator_t service_iterator;
    BCTransparentWindowOverlay *overlayManager;
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

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
    [overlayManager createOverlayWindows];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSSetUncaughtExceptionHandler(handleUncaughtException);
    
    @try
    {
        self.brightnessTableController.managedObjectContext = self.managedObjectContext;
        
        loginItem = [EMCLoginItem loginItem];
        overlayManager = [BCTransparentWindowOverlay transparentWindowOverlay];

        // Make sure slider view will be as wide as the contextual menu.
        [[self sliderView] setAutoresizingMask:NSViewWidthSizable];
        
        [self schedulePollTimer];
        [self scheduleStatusItemTimer];
        [self registerObservers];
        [self setDefaults];
        [self getDefaults];
        [self createDockIcon];
        [overlayManager createOverlayWindows];
        [self setBrightness:[self getCurrentBrightness]];
    }
    @catch (NSException * e)
    {
        handleUncaughtException(e);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [overlayManager setVisible:NO];
    [self invalidateStatusItemTimer];
    [self invalidatePollTimer];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (void)registerObservers
{
    [self addObserver:self
           forKeyPath:@"percentageShown"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"useOverlay"
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
    [self updateStatusItem];
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
        [self updateStatusItem];
    }
    
    if ([keyPath isEqualToString:@"useOverlay"])
    {
        [self onUseOverlay];
    }
    
    if ([keyPath isEqualToString:@"brightness"])
    {
        [self onUpdateBrightness];
    }
    
    if ([keyPath isEqualToString:@"restoreEnabled"])
    {
        [self updateRestoreItem];
        [self updateStatusItem];
    }
}

- (void)onUseOverlay
{
    [overlayManager setVisible:[self useOverlay]];
}

- (void)updateSliderAndSetBrightness:(NSNumber *)updatedBrightness
{
    [self setBrightness:[updatedBrightness floatValue]];
}

- (void)statusItemTimerFired:(NSTimer *)timer
{
    // Empty sun and green sun never poll.
    if ([self isActiveProfileValid] && ![self isRestoreEnabled])
    {
        [self updateStatusIcon];
        return;
    }
    
    NSDate *now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSince1970];
    
    // Start polling only when the last icon update happened after a .5 seconds.
    if (fabs(time - [self lastStatusIconUpdate]) < 0.5) return;

    if (((int)time) % 2)
    {
        [statusItem setImage:[NSImage imageNamed:@"sun"]];
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

- (void)createDockIcon
{
    if (statusItem != nil)
    {
        NSLog(@"Dock icon already set. This method should not be called twice.");
        return;
    }
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"sun"]];
    [statusItem setHighlightMode:YES];
    [statusItem setEnabled:TRUE];
    [statusItem setToolTip:@"Brightness Setter"];
    [statusItem setMenu:_dockMenu];
}

- (void)getDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [self setPercentageShown:[defaults boolForKey:kBSPercentageShownPropertyName]];
    [self setUseOverlay:[defaults boolForKey:kBSUseOverlayPropertyName]];
    [overlayManager setShowMainMenuAndDock:[defaults boolForKey:kBSOverlayBelowMainMenuPropertyName]];
}

- (void)setDefaults
{
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
    defaults[kBSPercentageShownPropertyName] = @(NO);
    defaults[kBSUseOverlayPropertyName] = @(NO);
    defaults[kBSOverlayBelowMainMenuPropertyName] = @(NO);
    defaults[kBSSortDescriptorsPropertyName] = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // setting defaults in shared controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
}

- (float)getCurrentBrightness
{
    std::vector<emc::display> active_displays = emc::display::find_active();

    if (active_displays.size() == 0)
    {
        NSLog(@"No active display have been found");
        return [self brightness];
    }

    return active_displays[0].get_brightness();
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

    std::vector<emc::display> active_displays = emc::display::find_active();
    for (auto& d : active_displays)
    {
        try {
        d.set_brightness([self brightness]);
        }
        catch (const std::runtime_error& err)
        {
            NSLog(@"%s", err.what());
        }
    }

    [self updateOverlay];
}

- (void)updateOverlay
{
    // If brightness is in the [0, .1] range, then we linearly darken the
    // overlay window.
    if ([self brightness] <= 0.1)
    {
        [self setOverlayAlpha:((float)1.0 - [self brightness] * 10)];
        [overlayManager setVisible:[self useOverlay]];
    } else {
        [self setOverlayAlpha:0.0];
        [overlayManager setVisible:NO];
    }
}

- (void)setOverlayAlpha:(float)alpha
{
    float adjustedValue = alpha + 1;
    adjustedValue = log2f(adjustedValue);

    NSLog(@"Setting overlay alpha: %f.", alpha);
    NSLog(@"Setting overlay alpha adjusted: %f.", adjustedValue);
    
    [overlayManager setAlpha:adjustedValue];
}

- (void)updateRestoreItem
{
    [[self restoreItem] setEnabled:[self isRestoreEnabled]];
}

- (NSString *)formatBrightnessString:(float)brightness
{
    return [NSString stringWithFormat:@"%.2f%%", brightness * 100];
}

- (void)updateStatusItem
{
    if ([self percentageShown])
    {
        [statusItem setTitle:[self formatBrightnessString:[self brightness]]];
    }
    else
    {
        [statusItem setTitle:nil];
    }
    
    [self updateStatusIcon];
}

- (void)updateStatusIcon
{
    const NSDate * now = [NSDate date];
    const NSTimeInterval currentIconUpdate = [now timeIntervalSince1970];
    const float savedBrightness = [self getCurrentProfileBrightnessValue];
    
    if (![BCUtils isBrightnessValid:savedBrightness])
    {
        [statusItem setImage:[NSImage imageNamed:@"sun"]];
    }
    else if ([self isRestoreEnabled])
    {
        [statusItem setImage:[NSImage imageNamed:@"sun_orange"]];
    }
    else
    {
        [statusItem setImage:[NSImage imageNamed:@"sun_green"]];
    }

    [self setLastStatusIconUpdate:currentIconUpdate];
}

- (void)updateSliderValue
{
    [self setSliderValue:([self brightness] * 100)];
}

- (BOOL)restoreEnabled
{
    return [self isRestoreEnabled];
}

- (BOOL)isActiveProfileValid
{
    return (self.activeProfile != nil && [self.brightnessTableController existsProfile:self.activeProfile]);
}

- (BOOL)isRestoreEnabled
{
    if (![self isActiveProfileValid]) return NO;
    
    const float savedBrightness = [self.brightnessTableController getProfileBrightness:self.activeProfile];

    return savedBrightness != _brightness && [BCUtils isBrightnessValid:savedBrightness];
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

- (void)selectProfile:(id)sender
{
    NSMenuItem *item = sender;
    
    // saving the current profile name
    self.activeProfile = item.title;

    float profileBrightness = [self getCurrentProfileBrightnessValue];

    NSLog(@"Chosen: %@, %f.", item.title, profileBrightness);
    
    // When a profile is chosen we save its name and trigger a KVO notification
    // on restoreEnabled through setBrightness.

    [self setBrightness:profileBrightness];
}

- (IBAction)restoreBrightness:(id)sender
{
    [self setBrightness:[self getCurrentProfileBrightnessValue]];
}

- (IBAction)showPercentage:(id)sender
{
    const BOOL newPercentageShown = ![self percentageShown];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(newPercentageShown)
                 forKey:kBSPercentageShownPropertyName];
    
    [self setPercentageShown:newPercentageShown];
}

- (IBAction)toggleUseOverlay:(id)sender
{
    const BOOL newUseOverlay = ![self useOverlay];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(newUseOverlay)
                 forKey:kBSUseOverlayPropertyName];
    
    [self setUseOverlay:newUseOverlay];
}

- (IBAction)toggleOverlayBelowMenuAndDock:(id)sender
{
    const BOOL newOverlayBelowMenuAndDock = ![overlayManager showMainMenuAndDock];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(newOverlayBelowMenuAndDock)
                 forKey:kBSOverlayBelowMainMenuPropertyName];
    
    [overlayManager setShowMainMenuAndDock:newOverlayBelowMenuAndDock];
}


- (IBAction)toggleLaunchAtLogin:(id)sender
{
    [self enableLoginItem:![loginItem isLoginItem]];
}

- (IBAction)showAboutWindow:(id)sender
{
    NSApplication * app = [NSApplication sharedApplication];
    [app orderFrontStandardAboutPanel:sender];
    [app activateIgnoringOtherApps:YES];
}

- (void)enableLoginItem:(BOOL)enable
{
    if (enable)
    {
        [loginItem addLoginItem];
    }
    else
    {
        [loginItem removeLoginItem];
    }
}

- (float)getCurrentProfileBrightnessValue
{
    return [self.brightnessTableController getProfileBrightness:self.activeProfile];
}

#pragma mark - Menu management

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    [self.profileMenuItem.submenu removeAllItems];
 
    NSArray *profileNames = self.brightnessTableController.profileNames;
    NSString *currentProfile = self.activeProfile;
    
    for (NSString *profileName in profileNames)
    {
        NSMenuItem *profileItem = [self.profileMenuItem.submenu addItemWithTitle:profileName action:@selector(selectProfile:) keyEquivalent:@""];
        if ([profileName isEqualToString:currentProfile])
        {
            [profileItem setState:NSOnState];
        }
    }
    
    [self.profileMenuItem setEnabled:([profileNames count] > 0)];
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
    
    if (act == @selector(toggleLaunchAtLogin:))
    {
        if ([obj respondsToSelector:@selector(setState:)])
        {
            [obj setState:([loginItem isLoginItem] ? NSOnState : NSOffState)];
        }
    }
    
    if (act == @selector(toggleUseOverlay:))
    {
        if ([obj respondsToSelector:@selector(setState:)])
        {
            [obj setState:([self useOverlay] ? NSOnState : NSOffState)];
        }
    }
    
    if (act == @selector(toggleOverlayBelowMenuAndDock:))
    {
        if ([obj respondsToSelector:@selector(setState:)])
        {
            [obj setState:(overlayManager.showMainMenuAndDock ? NSOnState : NSOffState)];
        }
    }
    
    if (act == @selector(restoreBrightness:))
    {
        return [self isRestoreEnabled];
    }
    
    return YES;
}

#pragma mark - Save Brightness

- (IBAction)saveWithName:(id)sender
{
    [self.saveWindow makeKeyAndOrderFront:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma mark - Profile Management

- (NSString *)activeProfile
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:kBSActiveProfilePropertyName];
}

- (void)setActiveProfile:(NSString *)profileName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:profileName forKey:kBSActiveProfilePropertyName];
}

#pragma mark - Core Data methods

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.blogspot.thegreyblog.Brightness-Control" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.blogspot.thegreyblog.Brightness-Control"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
    {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    
    if (!mom)
    {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties)
    {
        BOOL ok = NO;
        
        if ([error code] == NSFileReadNoSuchFileError)
        {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        if (!ok)
        {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else
    {
        if (![properties[NSURLIsDirectoryKey] boolValue])
        {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Brightness-Control.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext)
    {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges])
    {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    
    if (![[self managedObjectContext] save:&error])
    {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result)
        {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", nil);
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save.", nil);
        NSString *quitButton = NSLocalizedString(@"Quit anyway", nil);
        NSString *cancelButton = NSLocalizedString(@"Cancel", nil);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn)
        {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
