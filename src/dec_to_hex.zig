const std = @import("std");
const shared = @import("shared.zig");

pub fn main() !void {
    std.log.debug("stdinHasInput: {any}", .{shared.stdinHasInput()});
    if (try shared.stdinHasInput()) {
        try shared.convertFromStdin(.dec, .hex);
    }

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    try shared.convertFromArgs(arena, .dec, .hex);
}
