const std = @import("std");
const volt = @import("volt");

const filesys = @import("filesys.zig");

const Term = @import("term.zig");
const State = @import("state.zig");

const Hotkeys = enum(u8) {
    cursorUp = 'k',
    cursorDown = 'j',
    goToParent = 'h',
    goInCursored = 'l',
    _,
};

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
    const cwd: std.Io.Dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var state: State = undefined;
    try state.init(io, init.gpa, cwd);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buf);

    var terminal: Term = undefined;
    try terminal.initTerm();

    // try changeTerminalBuffer(&stdout);

    try stdout.interface.writeAll("\x1b[2J\x1b[H");
    try stdout.flush();
    try terminal.enableRawMode();

    // TODO: fix memory leaks (we allocate std.Io.Dir.Entry.name in arr)
    while (stdin_reader.interface.takeByte()) |byte| {
        const action: Hotkeys = @enumFromInt(byte);

        try clearScreen(&stdout);

        switch (action) {
            .goToParent => {
                try state.goToParent(io, init.gpa);
                try stdout.interface.writeAll("\x1b[2J\x1b[H");
            },
            .cursorDown => state.selectionDown(),
            .cursorUp => state.selectionUp(),
            .goInCursored => {
                try state.goInCursored(io, init.gpa);
                try stdout.interface.writeAll("\x1b[2J\x1b[H");
            },
            _ => {},
        }
        for (0..state.cwd_content.len) |i| {
            if (i == state.cursor_pos) try stdout.interface.writeAll("\x1B[7m");

            switch (state.cwd_content[i].kind) {
                .directory => try stdout.interface.print("{s}/\n", .{state.cwd_content[i].name}),
                else => try stdout.interface.print("{s}\n", .{state.cwd_content[i].name}),
            }

            if (i == state.cursor_pos) try stdout.interface.writeAll("\x1B[0m");
        }
        try stdout.interface.flush();
    } else |err| {
        return err;
    }

    try stdout.interface.flush();

    try terminal.disableRawMode();

    // try changeTerminalBufferBack(&stdout);
}
