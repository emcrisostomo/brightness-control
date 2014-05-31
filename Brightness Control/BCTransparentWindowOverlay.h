/*
 * BCTransparentWindowOverlay.h
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

#import <Foundation/Foundation.h>

@interface BCTransparentWindowOverlay : NSObject

+ (instancetype)transparentWindowOverlay;

- (void)createOverlayWindows;
- (void)updateOverlay;
- (void)setVisible:(BOOL)visible;

@property float alpha;
@property BOOL showMainMenuAndDock;
@property BOOL visible;
@property BOOL logarithmicScale;

@end
