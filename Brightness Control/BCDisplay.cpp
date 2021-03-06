//
//  BCDisplay.cpp
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 30/12/2019.
//  Copyright © 2019 Enrico Maria Crisostomo. All rights reserved.
//

#include "BCDisplay.hpp"
#include <sstream>
#include <stdexcept>
#include "object_guard.h"
#include <IOKit/graphics/IOGraphicsLib.h>

extern "C"
{
// macOS 10.12.4 introduces new undocumented APIs to control the display brightness.
// Weak link these symbols and use them if available.
// The linker has been configured to allow these symbols to be weak linked with:
//   -Wl,-U_symbol_name
double CoreDisplay_Display_GetUserBrightness(CGDirectDisplayID id) __attribute__((weak_import));
void CoreDisplay_Display_SetUserBrightness(CGDirectDisplayID id, double brightness) __attribute__((weak_import));
_Bool DisplayServicesCanChangeBrightness(CGDirectDisplayID id) __attribute__((weak_import));
void DisplayServicesBrightnessChanged(CGDirectDisplayID id, double brightness) __attribute__((weak_import));
}

namespace emc
{
  typedef object_guard<io_service_t, decltype(&IOObjectRelease), 0> service_guard;
  static service_guard find_io_service(CGDirectDisplayID display_id);
  static bool compare(CFNumberRef number, uint32_t uint32);
  static bool coredisplay_is_available();

  std::vector<display> display::find_active()
  {
    std::vector<display> active_displays;

    CGDirectDisplayID display_ids[DC_MAX_DISPLAYS];
    CGDisplayCount display_count;
    CGDisplayErr err = CGGetOnlineDisplayList(DC_MAX_DISPLAYS,
                                              display_ids,
                                              &display_count);
    if (err != CGDisplayNoErr)
    {
      std::ostringstream oss;
      oss << "CGGetOnlineDisplayList returned error: ";
      oss << err;

      throw std::runtime_error(oss.str());
    }

    for (CGDisplayCount i = 0; i < display_count; ++i)
    {
      CGDirectDisplayID display_id = display_ids[i];
      CGDisplayModeRef mode = CGDisplayCopyDisplayMode(display_id);

      if (mode == nullptr)
        continue;

      CGDisplayModeRelease(mode);

      active_displays.emplace_back(emc::display(display_id));
    }

    return active_displays;
  }

  display::display(CGDirectDisplayID display_id) : display_id(display_id)
  {
    //@formatter:off
    active = static_cast<bool>(CGDisplayIsActive(this->display_id));
    always_in_mirror_set = static_cast<bool>(CGDisplayIsAlwaysInMirrorSet(this->display_id));
    asleep = static_cast<bool>(CGDisplayIsAsleep(this->display_id));
    builtin = static_cast<bool>(CGDisplayIsBuiltin(this->display_id));
    in_hw_mirror_set = static_cast<bool>(CGDisplayIsInHWMirrorSet(this->display_id));
    in_mirror_set = static_cast<bool>(CGDisplayIsInMirrorSet(this->display_id));
    main = static_cast<bool>(CGDisplayIsMain(this->display_id));
    online = static_cast<bool>(CGDisplayIsOnline(this->display_id));
    stereo = static_cast<bool>(CGDisplayIsStereo(this->display_id));
    mirrored_display = CGDisplayMirrorsDisplay(this->display_id);
    opengl_used = static_cast<bool>(CGDisplayUsesOpenGLAcceleration(this->display_id));

    mirrored = (mirrored_display == kCGNullDirectDisplay);
    //@formatter:on
  }

  bool display::is_active() const
  {
    return active;
  }

  bool display::is_asleep() const
  {
    return asleep;
  }

  bool display::is_builtin() const
  {
    return builtin;
  }

  bool display::is_in_mirror_set() const
  {
    return in_mirror_set;
  }

  bool display::is_main() const
  {
    return main;
  }

  bool display::is_online() const
  {
    return online;
  }

  bool display::is_stereo() const
  {
    return stereo;
  }

  bool display::is_opengl_used() const
  {
    return opengl_used;
  }

  bool display::is_mirrored() const
  {
    return mirrored;
  }

  float display::get_brightness() const
  {
    if (coredisplay_is_available())
    {
      return coredisplay_get_brightness();
    }

    return iokit_get_brightness();
  }

  void display::set_brightness(float brightness)
  {
    if (coredisplay_is_available())
    {
      coredisplay_set_brightness(brightness);
      return;
    }

    iokit_set_brightness(brightness);
  }

  float display::coredisplay_get_brightness() const
  {
    if (!coredisplay_is_available())
      throw std::runtime_error("CoreDisplay is not available.");

    if (DisplayServicesCanChangeBrightness != nullptr
        && !DisplayServicesCanChangeBrightness(this->display_id))
    {
      std::ostringstream oss;
      oss << "Cannot get brightness of display: "
          << this->display_id;

      throw std::runtime_error(oss.str());
    }

    return (float) CoreDisplay_Display_GetUserBrightness(this->display_id);
  }

  float display::iokit_get_brightness() const
  {
    float current_brightness;

    service_guard service = find_io_service(this->display_id);
    IOReturn ret = IODisplayGetFloatParameter(service,
                                              kNilOptions,
                                              CFSTR(kIODisplayBrightnessKey),
                                              &current_brightness);

    if (ret != kIOReturnSuccess)
    {
      std::ostringstream oss;
      oss << "IODisplayGetFloatParameter returned error: " << ret;

      throw std::runtime_error(oss.str());
    }

    return current_brightness;
  }

  void display::coredisplay_set_brightness(float brightness)
  {
    if (!coredisplay_is_available())
      throw std::runtime_error("CoreDisplay is not available.");

    if (DisplayServicesCanChangeBrightness != nullptr
        && !DisplayServicesCanChangeBrightness(this->display_id))
    {
      std::ostringstream oss;
      oss << "Cannot set brightness of display: "
          << this->display_id;

      throw std::runtime_error(oss.str());
    }

    CoreDisplay_Display_SetUserBrightness(this->display_id, brightness);
    if (DisplayServicesBrightnessChanged != nullptr)
    {
      DisplayServicesBrightnessChanged(this->display_id, brightness);
    }
  }

  void display::iokit_set_brightness(float brightness)
  {
    service_guard service = find_io_service(this->display_id);

    IOReturn ret = IODisplaySetFloatParameter(service,
                                              kNilOptions,
                                              CFSTR(kIODisplayBrightnessKey),
                                              brightness);

    if (ret != kIOReturnSuccess)
    {
      std::ostringstream oss;
      oss << "IODisplaySetFloatParameter returned error: " << ret;

      throw std::runtime_error(oss.str());
    }
  }

  bool coredisplay_is_available()
  {
    return
      (CoreDisplay_Display_GetUserBrightness != nullptr
       && CoreDisplay_Display_SetUserBrightness != nullptr);
  }

  service_guard find_io_service(CGDirectDisplayID display_id)
  {
    uint32_t vendor = CGDisplayVendorNumber(display_id);
    uint32_t model = CGDisplayModelNumber(display_id);
    uint32_t serial = CGDisplaySerialNumber(display_id);

    io_iterator_t service_iterator;

    if (IOServiceGetMatchingServices(kIOMasterPortDefault,
                                     IOServiceMatching("IODisplayConnect"),
                                     &service_iterator) != kIOReturnSuccess)
      return service_guard(0, &IOObjectRelease);

    emc::object_guard<io_iterator_t, decltype(&IOObjectRelease), 0>
      service_iterator_guard(service_iterator, &IOObjectRelease);

    service_guard service(0, &IOObjectRelease);

    while ((service = service_guard(IOIteratorNext(service_iterator), &IOObjectRelease)) != (io_service_t) 0)
    {
      emc::object_guard<CFDictionaryRef, decltype(&CFRelease)> info(
        IODisplayCreateInfoDictionary(service, kIODisplayNoProductName),
        &CFRelease);

      auto vendorID = static_cast<CFNumberRef>(CFDictionaryGetValue(info, CFSTR(kDisplayVendorID)));
      auto productID = static_cast<CFNumberRef>(CFDictionaryGetValue(info, CFSTR(kDisplayProductID)));
      auto serialNumber = static_cast<CFNumberRef>(CFDictionaryGetValue(info, CFSTR(kDisplaySerialNumber)));

      if (compare(vendorID, vendor) &&
          compare(productID, model) &&
          compare(serialNumber, serial))
      {
        return service;
      }
    }

    return service_guard(0, &IOObjectRelease);
  }

  bool compare(CFNumberRef number, uint32_t uint32)
  {
    if (number == nullptr) return (uint32 == 0);

    int64_t number_value;

    return CFNumberGetValue(number,
                            kCFNumberSInt64Type,
                            &number_value) &&
           number_value == uint32;
  }
}
