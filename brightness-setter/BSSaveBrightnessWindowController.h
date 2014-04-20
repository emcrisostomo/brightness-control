/*
 * BSSaveBrightnessWindowController.h
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

void ( ^ closeWnd )( );

@interface BSSaveBrightnessWindowController : NSWindowController

- (void)reset;
- (void)setBrightness:(float)brightness;
- (IBAction)saveBrightness:(id)sender;

@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *okButton;
@property (strong) void ( ^ closeCallback )( bool );
@property (copy) NSString *settingName;
@property float brightness;

@end
