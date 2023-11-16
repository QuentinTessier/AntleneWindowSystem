const std = @import("std");

pub fn build(b: *std.Build) !void {
    const zigwin32 = b.dependency("zigwin32", .{});
    var module = b.createModule(.{
        .source_file = .{
            .path = "src/main.zig",
        },
        .dependencies = &.{
            .{
                .name = "zigwin32",
                .module = zigwin32.module("zigwin32"),
            },
        },
    });
    try b.modules.put(b.dupe("AntleneWindowSystem"), module);
}
