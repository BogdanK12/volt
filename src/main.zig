const std = @import("std");
const volt = @import("volt");
const Term = @import("term.zig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    _ = &args;
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    const io = init.io;
    const cwd: std.Io.Dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    const arr = try volt.filesys.dirToArray(init.io, init.gpa, cwd);
    defer init.gpa.free(arr);

    var terminal: Term = undefined;
    try terminal.initTerm();

    try terminal.enableRawMode();

    for (arr) |file| {
        try stdout_file_writer.interface.print("{s}\n", .{file});
        init.gpa.free(file);
    }

    try stdout_file_writer.interface.flush();

    try terminal.disableRawMode();
}
