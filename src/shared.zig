const std = @import("std");
const builtin = @import("builtin");

pub fn bufferedPrint(comptime fmt: []const u8, args: anytype) std.Io.Writer.Error!void {
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
pub fn stdinHasInput() std.posix.PollError!bool {
    const stdin_handle = std.fs.File.stdin().handle;
    var poll_request = [_]std.posix.pollfd{
        .{
            .fd = switch (builtin.target.os.tag) {
                .linux => stdin_handle,
                .windows => @ptrCast(stdin_handle),
                else => @compileError("Unsupported OS."),
            },
            .events = std.os.linux.POLL.IN,
            .revents = 0,
        },
    };

    const count = try std.posix.poll(&poll_request, 0);
    return count > 0;
}

pub const ConvertFromStdinError =
    error{ ReadFailed, StreamTooLong } || // error from std.Io.Reader.takeDelimiter
    ConvertError;

pub fn convertFromStdin(comptime from: Base, comptime to: Base) ConvertFromStdinError!void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    // TODO: test delimiters in windows
    while (try stdin.takeDelimiter('\n')) |input| {
        var word_iterator = std.mem.splitScalar(u8, input, ' ');
        std.log.debug("stdin input: {s}", .{input});
        while (word_iterator.next()) |word| {
            try convert(word, from, to);
        }
    }
}

pub const ConvertFromArgsError =
    std.process.ArgIterator.InitError ||
    ConvertError;

pub fn convertFromArgs(
    arena: std.mem.Allocator,
    comptime from: Base,
    comptime to: Base,
) ConvertFromArgsError!void {
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

const ConvertError =
    std.fmt.ParseIntError ||
    std.Io.Writer.Error;

fn convert(data: []const u8, comptime from: Base, comptime to: Base) ConvertError!void {
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
