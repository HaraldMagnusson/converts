const std = @import("std");
const builtin = @import("builtin");
const shared = @import("shared.zig");

pub fn main() !void {
    std.log.debug("stdinHasInput: {any}", .{stdinHasInput()});
    if (try stdinHasInput()) {
        try convertFromStdin();
    }

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

        const base_16 = 16;
        const nombre = std.fmt.parseInt(u256, arg, base_16) catch |err| {
            std.log.debug("invalid input: {s}", .{arg});
            return err;
        };

        try shared.bufferedPrint("{d}\n", .{nombre});
    }
}

/// TODO: test in windows
fn stdinHasInput() !bool {
    var poll_request = [_]std.posix.pollfd{
        .{
            .fd = std.fs.File.stdin().handle,
            .events = std.os.linux.POLL.IN,
            .revents = 0,
        },
    };

    const count = try std.posix.poll(&poll_request, 0);
    return count > 0;
}

fn convertFromStdin() !void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    // TODO: test delimiters in windows
    const input_str = try stdin.takeDelimiter('\n') orelse {
        std.log.debug("empty input", .{});
        return;
    };
    std.log.debug("stdin input: {s}", .{input_str});

    const base_16 = 16;
    const nombre = std.fmt.parseInt(u256, input_str, base_16) catch |err| {
        std.log.debug("invalid input: {s}", .{input_str});
        return err;
    };

    try shared.bufferedPrint("{d}\n", .{nombre});
}
