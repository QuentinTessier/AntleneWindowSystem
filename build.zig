const std = @import("std");

pub fn build(b: *std.Build) !void {
    const zigwin32 = b.dependency("zigwin32", .{});
    const module = b.createModule(.{ .source_file = .{
        .path = "src/main.zig",
    }, .dependencies = .{.{
        .name = "zigwin32",
        .module = zigwin32.module("zigwin32"),
    }} });
    try b.modules.put("AntleneWindowSystem", module);
}
