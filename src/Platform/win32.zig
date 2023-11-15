const std = @import("std");
const win32 = @import("zigwin32").everything;

pub const Window = struct {
    name: [*:0]const u8,
    extent: struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
    },

    // Win32 specific
    hInstance: win32.HINSTANCE = undefined,
    hwnd: win32.HWND = undefined,

    pub fn init(name: [*:0]const u8, width: i32, height: i32) Window {
        return .{ .name = name, .extent = .{
            .x = 0,
            .y = 0,
            .width = width,
            .height = height,
        } };
    }

    pub fn create(self: *Window) void {
        // TODO: Check for error
        self.hInstance = win32.GetModuleHandleA(null) orelse unreachable;

        var bBrush = win32.GetStockObject(win32.BLACK_BRUSH);
        _ = bBrush;
    }
};
