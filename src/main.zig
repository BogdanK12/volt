const std = @import("std");
const volt = @import("volt");
const Term = @import("term.zig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    _ = args;
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    const io = init.io;
    var cwd: std.Io.Dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    const stdout: std.Io.File = .stdout();
    _ = stdout;
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buf);

    var arr = try volt.filesys.dirToArray(init.io, init.gpa, cwd);
    defer init.gpa.free(arr);

    var terminal: Term = undefined;
    try terminal.initTerm();

    try terminal.enableRawMode();

    while (stdin_reader.interface.takeByte()) |byte| {
        if (byte == 'k') {
            cwd = try cwd.openDir(io, "..", .{ .iterate = true });
            for (arr) |file| {
                init.gpa.free(file);
            }
            init.gpa.free(arr);
            arr = try volt.filesys.dirToArray(io, init.gpa, cwd);
            try stdout_file_writer.interface.writeAll("\x1b[2J\x1b[H");
        }
        for (arr) |file| {
            try stdout_file_writer.interface.print("{s}\n", .{file});
        }
        try stdout_file_writer.interface.flush();
    } else |err| {
        return err;
    }

    try stdout_file_writer.interface.flush();

    try terminal.disableRawMode();
}
