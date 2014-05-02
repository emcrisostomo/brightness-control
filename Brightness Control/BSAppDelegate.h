/*
 * BSAppDelegate.h
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

#import <Cocoa/Cocoa.h>

@interface BSAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserInterfaceValidations> {
    NSStatusItem *statusItem;
    float _brightness;
    NSTimer *pollTimer;
    NSTimer *statusItemTimer;
    io_iterator_t service_iterator;
}

- (IBAction)updateValue:(id)sender;
- (IBAction)saveCurrentBrightness:(id)sender;
- (IBAction)restoreBrightness:(id)sender;
- (IBAction)showPercentage:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *dockMenu;
@property (weak) IBOutlet NSView *sliderView;
@property float brightness;
@property float sliderValue;
@property BOOL restoreEnabled;
@property BOOL percentageShown;
@property NSTimeInterval lastStatusIconUpdate;

@end

NSString * const kBSBrightnessPropertyName;
NSString * const kBSPercentageShownPropertyName;
const float      kBSBrightnessTolerance;