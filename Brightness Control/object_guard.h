//
//  object_guard.h
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 30/12/2019.
//  Copyright © 2019 Enrico Maria Crisostomo. All rights reserved.
//

#ifndef object_guard_h
#define object_guard_h

namespace emc
{
  template<typename T, typename F, T null_handle = nullptr>
  class object_guard
  {
  public:
    object_guard(T handle, F deleter) : handle(handle),
                                        deleter(deleter)
    {
    }

    object_guard(const object_guard&) = delete;
    object_guard& operator=(const object_guard&) = delete;

    object_guard(object_guard&& other) noexcept
    {
      deleter = other.deleter;
      handle = other.handle;
      other.handle = null_handle;
    }

    object_guard& operator=(object_guard&& other) noexcept
    {
      if (this == &other) return *this;

      if (handle != null_handle) deleter(handle);
      deleter = other.deleter;
      handle = other.handle;
      other.handle = null_handle;

      return *this;
    }

    virtual ~object_guard()
    {
      if (handle != null_handle)
        deleter(handle);
    }

    operator T() const
    {
      return handle;
    }

    bool operator==(const T& value) const
    {
      return handle == value;
    }

    bool operator!=(const T& value) const
    {
      return !(*this == value);
    }

  private:
    T handle;
    F deleter;
  };
}

#endif /* object_guard_h */
