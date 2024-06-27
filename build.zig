const std = @import("std");

pub fn build(b: *std.Build) !void {
    const zigwin32 = b.dependency("zigwin32", .{});
    const module = b.addModule("AntleneWindowSystem", .{
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .imports = &.{},
    });
    module.addImport("zigwin32", zigwin32.module("zigwin32"));
}
