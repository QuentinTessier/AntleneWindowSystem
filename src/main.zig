const std = @import("std");
const builtin = @import("builtin");

pub const Platform = enum {
    Windows,
    Wayland,
    X11,
};

pub fn PlatfromWindow() type {
    switch (builtin.os.tag) {
        .windows => {
            const Win32Window = @import("Platform/win32.zig").Window;
            return Win32Window;
        },
        else => {
            @panic("Lib only supports Windows right now");
        },
    }
}

const Window = PlatfromWindow();

pub fn main() anyerror!void {
    var window = Window.init("test", 1, 1);
    window.create();
}
