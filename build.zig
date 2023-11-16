const std = @import("std");

pub fn build(b: *std.Build) !void {
    const zigwin32 = b.dependency("zigwin32", .{});
    _ = b.addModule("AntleneWindowSystem", .{ .source_file = .{
        .path = "src/main.zig",
    }, .dependencies = &.{.{
        .name = "zigwin32",
        .module = zigwin32.module("zigwin32"),
    }} });
}
