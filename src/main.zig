const std = @import("std");
const builtin = @import("builtin");

pub const Platform = enum {
    Windows,
    Wayland,
    X11,
};

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

const Window = PlatfromWindow(Application);

const Application = struct {
    run: bool = true,

    pub fn onCloseEvent(self: *Application, _: *Window) void {
        self.run = false;
    }
};

pub fn main() anyerror!void {
    var app: Application = .{};
    var window = Window.init("test", 1000, 1000, &app);
    window.create();

    window.userdata = &app;

    while (app.run) {
        window.pollEvents();
    }
}
