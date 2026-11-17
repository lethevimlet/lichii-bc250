// SPDX-FileCopyrightText: Copyright 2026 lichii-bc250 contributors
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <atomic>
#include "common/common_types.h"

namespace Common::ProtectTag {

/// Which cache asked for the page protection change that is running (EDEN_NX2_PROTECT_STATS splits
/// the host mprotect calls by it).
enum Tag : int {
    Other = 0,
    TextureTrack,   ///< Texture cache: an image starts or stops being tracked
    TextureStale,   ///< Texture cache: stale pages of dropped GPU-written images
    Buffer,         ///< Buffer cache: CPU-tracked words of a buffer change (other paths)
    Shader,         ///< Shader cache: guest shader code tracked
    BufferUpload,   ///< Buffer cache: modified pages cleared after their upload
    BufferState,    ///< Buffer cache: a range marked modified or not (ChangeRegionState)
    BufferNotify,   ///< Buffer cache: NotifyRasterizer
    Count,
};

inline constexpr const char* names[Count]{"other",  "texture",       "texture stale", "buffer",
                                          "shader", "buffer upload", "buffer state",  "buffer notify"};

/// Pages the buffer cache protected again after an upload, and why they were not hot.
inline std::atomic<u64> g_upload_pages{}, g_upload_no_hot{}, g_upload_flipped{}, g_upload_fresh{};

inline int& Current() {
    thread_local int tag{Other};
    return tag;
}

/// Sets the tag for its lifetime.
struct Scope {
    /// keep: a tag set by a caller wins over this one.
    explicit Scope(Tag tag, bool keep = false) : previous{Current()} {
        if (!keep || previous == Other) {
            Current() = tag;
        }
    }
    ~Scope() {
        Current() = previous;
    }
    Scope(const Scope&) = delete;
    Scope& operator=(const Scope&) = delete;
    int previous;
};

} // namespace Common::ProtectTag
