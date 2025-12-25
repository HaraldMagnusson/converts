const std = @import("std");

const config = @import("build_config");
const Base = @import("base.zig").Base;

pub fn main() !void {
    const convert_from_int: usize = @intFromEnum(config.convert_from);
    const convert_to_int: usize = @intFromEnum(config.convert_to);
    const convert_from: Base = @enumFromInt(convert_from_int);
    const convert_to: Base = @enumFromInt(convert_to_int);

    std.log.debug("stdinHasInput: {any}", .{stdinHasInput()});
    if (stdinHasInput()) {
        try convertFromStdin(convert_from, convert_to);
    }

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    try convertFromArgs(arena, convert_from, convert_to);
}

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

pub fn stdinHasInput() bool {
    const stdin_handle = std.fs.File.stdin().handle;
    return !std.posix.isatty(stdin_handle);
}

pub const ConvertFromStdinError =
    error{ ReadFailed, StreamTooLong } || // error from std.Io.Reader.takeDelimiter
    ConvertError;

pub fn convertFromStdin(comptime from: Base, comptime to: Base) ConvertFromStdinError!void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    while (try stdin.takeDelimiter('\n')) |input| {
        const input_stripped = if (input[input.len - 1] == '\r') input[0 .. input.len - 1] else input;
        var word_iterator = std.mem.splitScalar(u8, input_stripped, ' ');
        std.log.debug("stdin input: {s}", .{input_stripped});
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

const ConvertError =
    std.fmt.ParseIntError ||
    std.Io.Writer.Error;

fn convert(data: []const u8, comptime from: Base, comptime to: Base) ConvertError!void {
    const base = switch (from) {
        .dec => 10,
        .hex => 16,
        .bin => 2,
        .oct => 8,
    };
    const nombre = std.fmt.parseInt(u256, data, base) catch |err| {
        std.log.debug("invalid input: {s}", .{data});
        return err;
    };

    const fmt = switch (to) {
        .dec => "d",
        .hex => "X",
        .bin => "b",
        .oct => "o",
    };
    try bufferedPrint("{" ++ fmt ++ "}\n", .{nombre});
}
