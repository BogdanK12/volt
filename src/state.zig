const std = @import("std");
const filesys = @import("filesys.zig");

const State = @This();

const Dir = std.Io.Dir;

pub const Error = error{
    NotADirectory,
};

parent_content: []Dir.Entry,
cwd_content: []Dir.Entry,
cwd: Dir,
cursor_pos: u64,

pub fn init(self: *State, io: std.Io, allocator: std.mem.Allocator, cwd: std.Io.Dir) !void {
    self.parent_content = try filesys.dirToArrayEntries(io, allocator, try cwd.openDir(io, "..", .{ .iterate = true }));
    self.cwd_content = try filesys.dirToArrayEntries(io, allocator, cwd);
    self.cwd = cwd;
    self.cursor_pos = 0;
}

pub fn selectionUp(self: *State) void {
    if (self.cursor_pos > 0) {
        self.cursor_pos -= 1;
    } else {
        self.cursor_pos = self.cwd_content.len - 1;
    }
}

pub fn selectionDown(self: *State) void {
    if (self.cursor_pos < self.cwd_content.len - 1) {
        self.cursor_pos += 1;
    } else {
        self.cursor_pos = 0;
    }
}

pub fn goToParent(self: *State, io: std.Io, allocator: std.mem.Allocator) !void {
    const temp = self.cwd;
    self.cwd = try self.cwd.openDir(io, "..", .{ .iterate = true });
    temp.close(io);

    for (self.cwd_content) |file| {
        allocator.free(file.name);
    }
    allocator.free(self.cwd_content);

    self.cwd_content = self.parent_content;
    self.parent_content = try filesys.dirToArrayEntries(io, allocator, try self.cwd.openDir(io, "..", .{ .iterate = true }));
    std.debug.print(
        "cwd={*} parent={*}\n",
        .{ self.cwd_content.ptr, self.parent_content.ptr },
    );
    self.cursor_pos = 0;
}

pub fn goInCursored(self: *State, io: std.Io, allocator: std.mem.Allocator) !void {
    if (self.cwd_content[self.cursor_pos].kind != .directory) return Error.NotADirectory;

    const path = try allocator.dupe(u8, self.cwd_content[self.cursor_pos].name);

    const temp = self.cwd;
    self.cwd = try self.cwd.openDir(io, path, .{ .iterate = true });

    for (self.parent_content) |file| {
        allocator.free(file.name);
    }
    allocator.free(self.parent_content);

    temp.close(io);
    self.parent_content = self.cwd_content;
    self.cwd_content = try filesys.dirToArrayEntries(io, allocator, self.cwd);
    self.cursor_pos = 0;

    allocator.free(path);
}
