const std = @import("std");

pub fn bufferedPrint(comptime fmt: []const u8, args: anytype) error{WriteFailed}!void {
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print(fmt, args);
    try stdout.flush();
}

test bufferedPrint {
    try bufferedPrint("I have {s} daughter.\n", .{"one"});
}

/// TODO: test in windows
pub fn stdinHasInput() !bool {
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

pub fn convertFromStdin() !void {
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

    try bufferedPrint("{d}\n", .{nombre});
}

pub fn convertFromArgs(arena: std.mem.Allocator, comptime from: Base, comptime to: Base) !void {
    var args = try std.process.argsWithAllocator(arena);
    defer args.deinit();

    _ = args.skip(); // skip executable name
    var arg_count: u32 = 0;
    while (args.next()) |arg| {
        arg_count += 1;
        std.log.debug("arg {d}: {s}", .{ arg_count, arg });

        try convert(arg, from, to);
    }
}

pub const Base = enum {
    dec,
    hex,
};

fn convert(data: []const u8, comptime from: Base, comptime to: Base) !void {
    const base = switch (from) {
        .dec => 10,
        .hex => 16,
    };
    const nombre = std.fmt.parseInt(u256, data, base) catch |err| {
        std.log.debug("invalid input: {s}", .{data});
        return err;
    };

    const fmt = switch (to) {
        .dec => "d",
        .hex => "X",
    };
    try bufferedPrint("{" ++ fmt ++ "}\n", .{nombre});
}
