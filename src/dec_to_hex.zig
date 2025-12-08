const std = @import("std");
const printing = @import("printing.zig");

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    var args = try std.process.argsWithAllocator(arena);
    defer args.deinit();

    _ = args.skip(); // skip executable name
    var arg_count: u32 = 0;
    while (args.next()) |arg| {
        arg_count += 1;
        std.log.debug("arg {d}: {s}", .{ arg_count, arg });

        const base_ten = 10;
        const nombre = std.fmt.parseInt(u256, arg, base_ten) catch |err| {
            std.log.debug("invalid input: {s}", .{arg});
            return err;
        };

        try printing.bufferedPrint("{X}\n", .{nombre});
    }
}
