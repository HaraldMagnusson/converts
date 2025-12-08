const std = @import("std");
const printing = @import("printing.zig");

pub fn main() !void {
    try printing.bufferedPrint("foo\n", .{});
}
