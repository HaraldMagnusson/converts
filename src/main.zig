const std = @import("std");
const shared = @import("shared.zig");
const config = @import("build_config");

pub fn main() !void {
    const convert_from_int: usize = @intFromEnum(config.convert_from);
    const convert_to_int: usize = @intFromEnum(config.convert_to);
    const convert_from: shared.Base = @enumFromInt(convert_from_int);
    const convert_to: shared.Base = @enumFromInt(convert_to_int);

    std.log.debug("stdinHasInput: {any}", .{shared.stdinHasInput()});
    if (shared.stdinHasInput()) {
        try shared.convertFromStdin(convert_from, convert_to);
    }

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    try shared.convertFromArgs(arena, convert_from, convert_to);
}
