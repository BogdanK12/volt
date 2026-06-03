const std = @import("std");
const filesys = @import("filesys.zig");

pub const State = struct {
    parent_content: [][]u8,
    cwd_content: [][]u8,
    cwd: std.Io.Dir,
    cursor_pos: u64,
};

pub fn initState(
    cstate: *State,
    init: std.process.Init,
    cwd: std.Io.Dir,
) !void {
    cstate.cwd = cwd;
    cstate.cwd_content = filesys.dirToArray(init, cwd);
    cstate.parent_content = filesys.dirToArray(init, cwd.openDir(init.io, "..", .{ .iterate = true }));
    cstate.cursor_pos = 0;
}

pub fn selectionUp(cstate: *State) void {
    if (cstate.cursor_pos > 0) {
        cstate.cursor_pos -= 1;
    } else {
        cstate.cursor_pos = cstate.cwd_content.len - 1;
    }
}

pub fn selectionDown(cstate: *State) void {
    if (cstate.cursor_pos < cstate.cwd_content.len - 1) {
        cstate.cursor_pos += 1;
    } else {
        cstate.cursor_pos = 0;
    }
}

// pub fn goToParent(cstate: *State, init: std.process.Init) !void {}
