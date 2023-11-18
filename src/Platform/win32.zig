const std = @import("std");
const win32 = @import("zigwin32").everything;
const WinApi = std.os.windows.WINAPI;

const Events = @import("../Event.zig");

const WM_RESHAPE = win32.WM_USER + 0;
const WM_ACTIVE = win32.WM_USER + 1;

pub fn loWord(x: isize) i16 {
    @setRuntimeSafety(false);
    return @intCast(x & 0xffff);
}

pub fn hiWord(x: isize) i16 {
    @setRuntimeSafety(false);
    return @intCast((x >> 16) & 0xffff);
}

const WIN32_TO_HID: [256]u8 = [256]u8{
    0, 0, 0, 0, 0, 0, 0, 0, 42, 43, 0, 0, 0, 40, 0, 0, // 16
    225, 224, 226, 72, 57, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, // 32
    44, 75, 78, 77, 74, 80, 82, 79, 81, 0, 0, 0, 70, 73, 76, 0, // 48
    39, 30, 31, 32, 33, 34, 35, 36, 37, 38, 0, 0, 0, 0, 0, 0, // 64
    0, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, // 80
    19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 0, 0, 0, 0, 0, // 96
    98, 89, 90, 91, 92, 93, 94, 95, 96, 97, 85, 87, 0, 86, 99, 84, //112
    58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 104, 105, 106, 107, //128
    108, 109, 110, 111, 112, 113, 114, 115, 0, 0, 0, 0, 0, 0, 0, 0, //144
    83, 71, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //160
    225, 229, 224, 228, 226, 230, 0, 0, 0, 0, 0, 0, 0, 127, 128, 129, //176    L/R shift/ctrl/alt  mute/vol+/vol-
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 51, 46, 54, 45, 55, 56, //192
    53, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //208
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 49, 48, 52, 0, //224
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //240
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //256
};

fn wndProc(hwnd: win32.HWND, msg: c_uint, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(WinApi) win32.LRESULT {
    switch (msg) {
        win32.WM_CLOSE => {
            _ = win32.DestroyWindow(hwnd);
            return 0;
        },
        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0;
        },
        win32.WM_PAINT => {
            _ = win32.ValidateRect(hwnd, null);
            return 0;
        },
        win32.WM_EXITSIZEMOVE => {
            _ = win32.PostMessageA(hwnd, WM_RESHAPE, 0, 0);
            return 0;
        },
        else => return win32.DefWindowProcA(hwnd, msg, wParam, lParam),
    }
    return 0;
}

// TODO: Check GetLastError when function fails and returns a error
pub fn Window(comptime UserDataType: type) type {
    return struct {
        const Self = @This();

        name: [*:0]const u8,
        extent: struct {
            x: i32,
            y: i32,
            width: i32,
            height: i32,
        },
        hasFocus: bool = true,

        // Win32 specific
        hInstance: win32.HINSTANCE = undefined,
        hwnd: win32.HWND = undefined,
        dc: win32.HDC = undefined,

        // Callbacks
        userdata: *UserDataType,

        closeCallback: ?*const fn (*UserDataType, *Self) void = if (@hasDecl(UserDataType, "onCloseEvent")) &UserDataType.onCloseEvent else null,
        keyCallback: ?*const fn (*UserDataType, *Self, Events.KeyEvent) void = if (@hasDecl(UserDataType, "onKeyEvent")) &UserDataType.onKeyEvent else null,

        mouseButtonCallback: ?*const fn (*UserDataType, *Self, Events.MouseButtonEvent) void = if (@hasDecl(UserDataType, "onMouseButtonEvent")) &UserDataType.onMouseButtonEvent else null,
        mouseScrollCallback: ?*const fn (*UserDataType, *Self, Events.MouseScrollEvent) void = if (@hasDecl(UserDataType, "onMouseScrollEvent")) &UserDataType.onMouseScrollEvent else null,
        mouseMovedCallback: ?*const fn (*UserDataType, *Self, Events.MouseMovedEvent) void = if (@hasDecl(UserDataType, "onMouseMovedEvent")) &UserDataType.onMouseMovedEvent else null,

        moveCallback: ?*const fn (*UserDataType, *Self, Events.MovedEvent) void = if (@hasDecl(UserDataType, "onWindowMoveEvent")) &UserDataType.onWindowMoveEvent else null,
        resizeCallback: ?*const fn (*UserDataType, *Self, Events.ResizeEvent) void = if (@hasDecl(UserDataType, "onWindowResizeEvent")) &UserDataType.onWindowResizeEvent else null,
        focusCallback: ?*const fn (*UserDataType, *Self, Events.FocusEvent) void = if (@hasDecl(UserDataType, "onWindowFocusEvent")) &UserDataType.onWindowFocusEvent else null,

        pub fn init(name: [*:0]const u8, width: i32, height: i32, userdata: *UserDataType) Self {
            return .{
                .name = name,
                .extent = .{
                    .x = 0,
                    .y = 0,
                    .width = width,
                    .height = height,
                },
                .userdata = userdata,
            };
        }

        pub fn create(self: *Self) void {
            // TODO: Check for error
            self.hInstance = win32.GetModuleHandleA(null) orelse unreachable;

            var bBrush = win32.GetStockObject(win32.BLACK_BRUSH);
            const wcex = win32.WNDCLASSEXA{
                .cbSize = @sizeOf(win32.WNDCLASSEXA),
                .style = win32.WNDCLASS_STYLES.initFlags(.{ .VREDRAW = 1, .HREDRAW = 1 }),
                .lpfnWndProc = wndProc,
                .cbClsExtra = 0,
                .cbWndExtra = 0,
                .hInstance = self.hInstance,
                .hIcon = null,
                .hCursor = null,
                .hbrBackground = @ptrCast(bBrush),
                .lpszMenuName = null,
                .lpszClassName = self.name,
                .hIconSm = null,
            };
            _ = win32.RegisterClassExA(&wcex);
            self.hwnd = win32.CreateWindowExA(
                win32.WINDOW_EX_STYLE.initFlags(.{}),
                self.name,
                self.name,
                win32.WINDOW_STYLE.initFlags(.{ .OVERLAPPED = 1, .CLIPCHILDREN = 1, .CLIPSIBLINGS = 1, .SYSMENU = 1, .VISIBLE = 1 }),
                self.extent.x,
                self.extent.y,
                self.extent.width,
                self.extent.height,
                null,
                null,
                self.hInstance,
                null,
            ) orelse unreachable;
            _ = win32.ShowWindow(self.hwnd, win32.SW_SHOW);
            self.dc = win32.GetDC(self.hwnd) orelse unreachable;
            return;
        }

        fn convertMessage(self: *Self, msg: win32.MSG) void {
            const mX: i16 = loWord(msg.lParam);
            const mY: i16 = hiWord(msg.lParam);

            switch (msg.message) {
                win32.WM_QUIT => {
                    if (self.closeCallback) |callback| {
                        callback(self.userdata, self);
                    }
                    return;
                },
                win32.WM_MOUSEMOVE => {
                    if (self.mouseMovedCallback) |callback| {
                        callback(self.userdata, self, .{ .x = @intCast(mX), .y = @intCast(mY) });
                    }
                    return;
                },
                win32.WM_LBUTTONDOWN => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .pressed = .Left });
                    }
                    return;
                },
                win32.WM_MBUTTONDOWN => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .pressed = .Middle });
                    }
                    return;
                },
                win32.WM_RBUTTONDOWN => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .pressed = .Right });
                    }
                    return;
                },
                win32.WM_LBUTTONUP => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .released = .Left });
                    }
                    return;
                },
                win32.WM_MBUTTONUP => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .released = .Middle });
                    }
                    return;
                },
                win32.WM_RBUTTONUP => {
                    if (self.mouseButtonCallback) |callback| {
                        callback(self.userdata, self, .{ .released = .Right });
                    }
                    return;
                },
                win32.WM_MOUSEWHEEL => {
                    const value = hiWord(@intCast(msg.wParam));
                    if (self.mouseScrollCallback) |callback| {
                        callback(self.userdata, self, .{ .amount = @floatFromInt(value) });
                    }
                    return;
                },
                win32.WM_KEYDOWN => {
                    if (self.keyCallback) |callback| {
                        const keycode = @as(Events.KeyCode, @enumFromInt(WIN32_TO_HID[@as(usize, msg.wParam)]));
                        callback(self.userdata, self, .{ .pressed = keycode });
                    }
                    return;
                },
                win32.WM_KEYUP => {
                    if (self.keyCallback) |callback| {
                        const keycode = @as(Events.KeyCode, @enumFromInt(WIN32_TO_HID[@as(usize, msg.wParam)]));
                        callback(self.userdata, self, .{ .released = keycode });
                    }
                    return;
                },
                WM_ACTIVE => {
                    self.hasFocus = msg.wParam != 0x0006;
                    if (self.focusCallback) |callback| {
                        callback(self.userdata, self, .{ .hasFocus = self.hasFocus });
                    }
                    return;
                },
                WM_RESHAPE => {
                    if (!self.hasFocus) {
                        _ = win32.PostMessageA(self.hwnd, WM_RESHAPE, msg.wParam, msg.lParam);
                        self.hasFocus = true;
                    }

                    var rect: win32.RECT = win32.RECT{ .left = 0, .right = 0, .top = 0, .bottom = 0 };
                    {
                        _ = win32.GetClientRect(self.hwnd, &rect);
                        const w = rect.right - rect.left;
                        const h = rect.bottom - rect.top;
                        if (self.resizeCallback) |callback| {
                            callback(self.userdata, self, .{
                                .old = .{ .width = self.extent.width, .height = self.extent.height },
                                .new = .{ .width = @intCast(w), .height = @intCast(h) },
                            });
                            self.extent.width = @intCast(w);
                            self.extent.height = @intCast(h);
                        }
                    }

                    {
                        _ = win32.GetWindowRect(self.hwnd, &rect);
                        const x = rect.left;
                        const y = rect.top;
                        if (self.moveCallback) |callback| {
                            callback(self.userdata, self, .{
                                .old = .{ .x = self.extent.x, .y = self.extent.y },
                                .new = .{ .x = x, .y = y },
                            });
                            self.extent.x = x;
                            self.extent.y = y;
                        }
                    }
                },
                else => {
                    return;
                },
            }
        }

        pub fn pollEvents(self: *Self) void {
            var msg: win32.MSG = undefined;
            while (win32.PeekMessageA(&msg, null, 0, 0, win32.PEEK_MESSAGE_REMOVE_TYPE.REMOVE) == 1) {
                _ = win32.TranslateMessage(&msg);

                self.convertMessage(msg);

                _ = win32.DispatchMessageA(&msg);
            }
        }

        pub fn getProcAddr() *const fn (?[*:0]const u8) callconv(WinApi) ?win32.PROC {
            return win32.wglGetProcAddress;
        }
    };
}
