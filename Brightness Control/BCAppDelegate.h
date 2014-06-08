/*
 * BSAppDelegate.h
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

#import <Cocoa/Cocoa.h>

@interface BCAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserInterfaceValidations>

- (IBAction)updateValue:(id)sender;
- (IBAction)saveCurrentBrightness:(id)sender;
- (IBAction)restoreBrightness:(id)sender;
- (IBAction)showPercentage:(id)sender;
- (IBAction)toggleUseOverlay:(id)sender;
- (IBAction)toggleLaunchAtLogin:(id)sender;
- (IBAction)showAboutWindow:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *dockMenu;
@property (weak) IBOutlet NSView *sliderView;
@property (weak) IBOutlet NSMenuItem *restoreItem;
@property float brightness;
@property float sliderValue;
@property BOOL restoreEnabled;
@property BOOL percentageShown;
@property BOOL useOverlay;
@property NSTimeInterval lastStatusIconUpdate;
// Core Data outlets
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

NSString * const kBSBrightnessPropertyName;
NSString * const kBSPercentageShownPropertyName;
const float      kBSBrightnessTolerance;
