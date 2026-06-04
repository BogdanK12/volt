const std = @import("std");
const volt = @import("volt");
const Term = @import("term.zig");

pub fn changeTerminalBuffer(stdout: *std.Io.File.Writer) !void {
    try stdout.interface.writeAll("\x1b[?1049h");
    try stdout.interface.flush();
}

pub fn changeTerminalBufferBack(stdout: *std.Io.File.Writer) !void {
    try stdout.interface.writeAll("\x1b[?1049l");
    try stdout.interface.flush();
}

pub fn clearScreen(stdout: *std.Io.File.Writer) !void {
    try stdout.interface.writeAll("\x1b[2J\x1b[H");
    try stdout.interface.flush();
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    _ = args;
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    const io = init.io;
    var cwd: std.Io.Dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var stdout_buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buf);

    var arr = try volt.filesys.dirToArrayEntries(init.io, init.gpa, cwd);
    defer init.gpa.free(arr);

    var terminal: Term = undefined;
    try terminal.initTerm();

    // try changeTerminalBuffer(&stdout);

    try stdout.interface.writeAll("\x1b[2J\x1b[H");
    try stdout.flush();
    try terminal.enableRawMode();

    while (stdin_reader.interface.takeByte()) |byte| {
        try clearScreen(&stdout);
        if (byte == 'k') {
            cwd = try cwd.openDir(io, "..", .{ .iterate = true });
            // for (arr) |file| {
            //     init.gpa.free(file);
            // }
            init.gpa.free(arr);
            arr = try volt.filesys.dirToArrayEntries(io, init.gpa, cwd);
            try stdout.interface.writeAll("\x1b[2J\x1b[H");
        }
        for (arr) |file| {
            switch (file.kind) {
                .directory => try stdout.interface.print("{s}/\n", .{file.name}),
                else => try stdout.interface.print("{s}\n", .{file.name}),
            }
        }
        try stdout.interface.flush();
    } else |err| {
        return err;
    }

    try stdout.interface.flush();

    try terminal.disableRawMode();

    // try changeTerminalBufferBack(&stdout);
}
