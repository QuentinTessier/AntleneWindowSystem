const std = @import("std");
const builtin = @import("builtin");

pub const Events = @import("Event.zig");

pub fn PlatfromWindow(comptime UserDataType: type) type {
    switch (builtin.os.tag) {
        .windows => {
            const Win32Window = @import("Platform/win32.zig").Window;
            return Win32Window(UserDataType);
        },
        else => {
            @panic("Lib only supports Windows right now");
        },
    }
}
