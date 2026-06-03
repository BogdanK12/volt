const std = @import("std");
const volt = @import("volt");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    _ = &args;
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    const io = init.io;
    // const cwd: std.Io.Dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    try stdout_file_writer.interface.flush();
}
