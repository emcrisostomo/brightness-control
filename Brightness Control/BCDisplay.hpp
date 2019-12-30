//
//  BCDisplay.hpp
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 30/12/2019.
//  Copyright © 2019 Enrico Maria Crisostomo. All rights reserved.
//

#ifndef BCDisplay_hpp
#define BCDisplay_hpp

#include <vector>
#include <ApplicationServices/ApplicationServices.h>

namespace emc
{
  class display
  {
  public:
    static std::vector<display> find_active();

    display(const display&) = delete;
    display& operator=(const display&) = delete;
    display(display&& other) noexcept = default;

    display& operator=(display&& other) noexcept = default;
    bool is_active() const;
    bool is_asleep() const;
    bool is_builtin() const;
    bool is_in_mirror_set() const;
    bool is_main() const;
    bool is_online() const;
    bool is_stereo() const;
    bool is_opengl_used() const;
    bool is_mirrored() const;
    float get_brightness() const;
    void set_brightness(float brightness);

  private:
    display(CGDirectDisplayID display_id);
    float coredisplay_get_brightness() const;
    void coredisplay_set_brightness(float brightness);
    float iokit_get_brightness() const;
    void iokit_set_brightness(float brightness);

    static const int DC_MAX_DISPLAYS = 128;
    CGDirectDisplayID display_id;
    bool active;
    bool always_in_mirror_set;
    bool asleep;
    bool builtin;
    bool in_hw_mirror_set;
    bool in_mirror_set;
    bool main;
    bool online;
    bool stereo;
    CGDirectDisplayID mirrored_display;
    bool opengl_used;
    bool mirrored;
  };
}

#endif /* BCDisplay_hpp */
