const std = @import("std");
const win32 = @import("zigwin32").everything;
const winGL = @import("zigwin32").graphics.open_gl;

const PFN_WGLCREATECONTEXTATTRIBSARBPROC = *const fn (win32.HDC, ?win32.HGLRC, [*]const i32) callconv(.C) ?win32.HGLRC;
const PFN_WGLCHOOSEPIXELFORMATARBPROC = *const fn (win32.HDC, [*]const i32, ?[*]const f32, u32, *win32.PFD_PIXEL_TYPE, *u32) callconv(.C) win32.BOOL;

const WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
const WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;
const WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126;

const WGL_DRAW_TO_WINDOW_ARB = 0x2001;
const WGL_ACCELERATION_ARB = 0x2003;
const WGL_SUPPORT_OPENGL_ARB = 0x2010;
const WGL_DOUBLE_BUFFER_ARB = 0x2011;
const WGL_PIXEL_TYPE_ARB = 0x2013;
const WGL_COLOR_BITS_ARB = 0x2014;
const WGL_DEPTH_BITS_ARB = 0x2022;
const WGL_STENCIL_BITS_ARB = 0x2023;

const WGL_FULL_ACCELERATION_ARB = 0x2027;
const WGL_TYPE_RGBA_ARB = 0x202B;

const WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 1;

const LoadFunction = struct {
    wglCreateContextAttribsARB: PFN_WGLCREATECONTEXTATTRIBSARBPROC,
    wglChoosePixelFormatARB: PFN_WGLCHOOSEPIXELFORMATARBPROC,
};

pub fn loadFunction(comptime T: type, name: [*:0]const u8) !T {
    const ptr = win32.wglGetProcAddress(name);
    if (ptr) |p| {
        return @ptrCast(p);
    } else {
        std.log.err("Failed to load function {s}", .{name});
        return error.FailedToLoadGlFunction;
    }
}

fn loadWin32OpenGLExtensions(instance: win32.HINSTANCE) !LoadFunction {
    const wcex = win32.WNDCLASSEXA{
        .cbSize = @sizeOf(win32.WNDCLASSEXA),
        .style = .{ .VREDRAW = 1, .HREDRAW = 1, .OWNDC = 1 },
        .lpfnWndProc = win32.DefWindowProcA,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = instance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = "OpenGl Extension Loader",
        .hIconSm = null,
    };
    if (win32.RegisterClassExA(&wcex) == 0) {
        return error.FailedToRegisterClass;
    }

    const window = win32.CreateWindowExA(
        .{},
        "OpenGl Extension Loader",
        "OpenGl Extension Loader",
        .{},
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        null,
        null,
        instance,
        null,
    ) orelse return error.FailedToCreateWindow;

    const dc = win32.GetDC(window);

    const pfd = std.mem.zeroInit(win32.PIXELFORMATDESCRIPTOR, .{
        .nSize = @sizeOf(win32.PIXELFORMATDESCRIPTOR),
        .nVersion = 1,
        .iPixelType = win32.PFD_TYPE_RGBA,
        .dwFlags = .{ .DRAW_TO_WINDOW = 1, .SUPPORT_OPENGL = 1, .DOUBLEBUFFER = 1 },
        .cColorBits = 32,
        .cAlphaBits = 8,
        .iLayerType = win32.PFD_MAIN_PLANE,
        .cDepthBits = 24,
        .cStencilBits = 8,
    });

    const pixel_format = win32.ChoosePixelFormat(dc, &pfd);
    if (pixel_format == 0) {
        return error.PixelFormat;
    }
    if (win32.SetPixelFormat(dc, pixel_format, &pfd) == 0) {
        return error.PixelFormat;
    }

    const context = win32.wglCreateContext(dc);
    if (context == null) {
        return error.DummyContextCreateFailed;
    }
    if (win32.wglMakeCurrent(dc, context) == 0) {
        return error.MakeCurrentContextFailed;
    }

    const wglCreateContextAttribsARB = try loadFunction(PFN_WGLCREATECONTEXTATTRIBSARBPROC, "wglCreateContextAttribsARB");
    const wglChoosePixelFormatARB = try loadFunction(PFN_WGLCHOOSEPIXELFORMATARBPROC, "wglChoosePixelFormatARB");

    if (win32.wglMakeCurrent(dc, null) == 0) {
        return error.MakeCurrentContextFailed;
    }
    if (win32.wglDeleteContext(context) == 0) {
        return error.DeleteContextFailed;
    }
    _ = win32.ReleaseDC(window, dc.?);
    _ = win32.DestroyWindow(window);

    return .{
        .wglCreateContextAttribsARB = wglCreateContextAttribsARB,
        .wglChoosePixelFormatARB = wglChoosePixelFormatARB,
    };
}

pub fn loadWin32OpenGLContext(instance: win32.HINSTANCE, dc: win32.HDC, major: i32, minor: i32) !win32.HGLRC {
    const funs: LoadFunction = try loadWin32OpenGLExtensions(instance);

    const pixel_format_attribs = [_]i32{
        WGL_DRAW_TO_WINDOW_ARB, 1,
        WGL_SUPPORT_OPENGL_ARB, 1,
        WGL_DOUBLE_BUFFER_ARB,  1,
        WGL_ACCELERATION_ARB,   WGL_FULL_ACCELERATION_ARB,
        WGL_PIXEL_TYPE_ARB,     WGL_TYPE_RGBA_ARB,
        WGL_COLOR_BITS_ARB,     32,
        WGL_DEPTH_BITS_ARB,     24,
        WGL_STENCIL_BITS_ARB,   8,
        0,
    };

    var pixel_format: win32.PFD_PIXEL_TYPE = undefined;
    var num_format: u32 = 0;
    _ = funs.wglChoosePixelFormatARB(dc, &pixel_format_attribs, null, 1, &pixel_format, &num_format);
    if (num_format == 0) {
        std.log.err("Failed to retrieve pixel format for OpenGL{}.{}", .{ major, minor });
        return error.PixelFormat;
    }

    var pfd: win32.PIXELFORMATDESCRIPTOR = undefined;
    _ = win32.DescribePixelFormat(dc, pixel_format, @sizeOf(@TypeOf(pfd)), &pfd);
    if (win32.SetPixelFormat(dc, @intFromEnum(pixel_format), &pfd) == 0) {
        std.log.err("Failed to set pixel format for OpenGL{}.{}", .{ major, minor });
        return error.PixelFormat;
    }

    const gl_attribs = [_]i32{
        WGL_CONTEXT_MAJOR_VERSION_ARB, major,
        WGL_CONTEXT_MINOR_VERSION_ARB, minor,
        WGL_CONTEXT_PROFILE_MASK_ARB,  WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
        0,
    };

    const gl_context = funs.wglCreateContextAttribsARB(dc, null, &gl_attribs);
    if (gl_context == null) {
        std.log.err("Failed to create context for OpenGL{}.{}", .{ major, minor });
        return error.OpenGLContext;
    }

    if (win32.wglMakeCurrent(dc, gl_context) == 0) {
        std.log.err("Failed to set context for OpenGL{}.{}", .{ major, minor });
        return error.OpenGLContext;
    }
    return gl_context.?;
}
