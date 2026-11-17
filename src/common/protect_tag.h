// SPDX-FileCopyrightText: Copyright 2026 lichii-bc250 contributors
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

namespace Common::ProtectTag {

/// Which cache asked for the page protection change that is running (EDEN_NX2_PROTECT_STATS splits
/// the host mprotect calls by it).
enum Tag : int {
    Other = 0,
    TextureTrack,   ///< Texture cache: an image starts or stops being tracked
    TextureStale,   ///< Texture cache: stale pages of dropped GPU-written images
    Buffer,         ///< Buffer cache: CPU-tracked words of a buffer change
    Shader,         ///< Shader cache: guest shader code tracked
    Count,
};

inline constexpr const char* names[Count]{"other", "texture", "texture stale", "buffer", "shader"};

inline int& Current() {
    thread_local int tag{Other};
    return tag;
}

/// Sets the tag for its lifetime.
struct Scope {
    explicit Scope(Tag tag) : previous{Current()} {
        Current() = tag;
    }
    ~Scope() {
        Current() = previous;
    }
    Scope(const Scope&) = delete;
    Scope& operator=(const Scope&) = delete;
    int previous;
};

} // namespace Common::ProtectTag
