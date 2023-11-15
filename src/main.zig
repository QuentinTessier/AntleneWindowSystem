const std = @import("std");

pub const Platform = enum {
    Windows,
    Wayland,
    X11,
};
