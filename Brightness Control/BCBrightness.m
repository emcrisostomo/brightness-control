/*
* BCBrightness.m
* Brightness Control
*
* Copyright (C) 2019 Enrico M. Crisostomo
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

#import "BCBrightness.h"

@implementation BCBrightness
{
    io_iterator_t service_iterator;
}

// macOS 10.12.4 introduces new undocumented APIs to control the display brightness.
// Weak link these symbols and use them if available.
// The linker has been configured to allow these symbols to be weak linked with:
//   -Wl,-U_symbol_name
extern double CoreDisplay_Display_GetUserBrightness(CGDirectDisplayID id)                    __attribute__((weak_import));
extern void   CoreDisplay_Display_SetUserBrightness(CGDirectDisplayID id, double brightness) __attribute__((weak_import));
extern _Bool  DisplayServicesCanChangeBrightness(CGDirectDisplayID id)                       __attribute__((weak_import));
extern void   DisplayServicesBrightnessChanged(CGDirectDisplayID id, double brightness)      __attribute__((weak_import));

- (instancetype)init
{
    self = [super init];
    if (self == nil)
        return nil;

    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &service_iterator);

    if (result != kIOReturnSuccess)
    {
        NSLog(@"IOServiceGetMatchingServices failed.");
        [NSException raise:@"IOServiceGetMatchingServices failed."
                    format:@"IOServiceGetMatchingServices failed."];
    }

    return self;
}

- (void)dealloc
{
    IOObjectRelease(service_iterator);
}

- (float)getCurrentBrightness
{
    IOIteratorReset(service_iterator);

    io_object_t service;
    float currentValue = 1;

    NSMutableArray *brightnessValues = [[NSMutableArray alloc] init];

    while ((service = IOIteratorNext(service_iterator)))
    {
        IODisplayGetFloatParameter(service,
                                   kNilOptions,
                                   CFSTR(kIODisplayBrightnessKey),
                                   &currentValue);
        [brightnessValues addObject:[NSNumber numberWithFloat:currentValue]];
        IOObjectRelease(service);
    }

    if ([brightnessValues count] > 0)
    {
        currentValue = [[brightnessValues objectAtIndex:0] floatValue];
    }

    return currentValue;
}

- (void)setBrightness:(float)brightness
{
    NSLog(@"Setting brightness value: %f.", brightness);

    IOIteratorReset(service_iterator);

    io_object_t service;
    while ((service = IOIteratorNext(service_iterator)))
    {
        IODisplaySetFloatParameter(service,
                                   kNilOptions,
                                   CFSTR(kIODisplayBrightnessKey),
                                   brightness);
        IOObjectRelease(service);
    }
}

@end
