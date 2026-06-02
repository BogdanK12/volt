const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

const volt = @import("volt");

const separator: []const u8 = switch (builtin.os.tag) {
    .linux => "/",
    else => unreachable,
};

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;
    const cwd: Io.Dir = try Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var iter = cwd.iterate();

    while (iter.next(io)) |file| {
        if (file) |f| {
            switch (f.kind) {
                .directory => {
                    try stdout_writer.print("{s}/\n", .{f.name});
                },
                else => try stdout_writer.print("{s}\n", .{f.name}),
            }
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    try stdout_writer.flush();
}
