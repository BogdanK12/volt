const std = @import("std");

/// counts files in directory
pub fn nfilesInDir(io: std.Io, dir: std.Io.Dir) !u64 {
    var iter = dir.iterate();

    var filesNumber: u64 = 0;

    while (iter.next(io)) |file| {
        if (file) |f| {
            filesNumber += 1;
            _ = f;
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    return filesNumber;
}

/// creates array of strings with names of files in directory
pub fn dirToArray(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) ![][]u8 {
    var iter = dir.iterate();
    const filesNumber: u64 = try nfilesInDir(io, dir);

    if (filesNumber == 0) return &[_][]u8{};

    var arr: [][]u8 = try allocator.alloc([]u8, filesNumber);

    var i: u64 = 0;

    while (iter.next(io)) |file| {
        if (file) |f| {
            arr[i] = try allocator.dupe(u8, f.name);
            i += 1;
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    return arr;
}

/// creates array of std.Io.Dir.Entry with names of files in directory
pub fn dirToArrayEntries(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) ![]std.Io.Dir.Entry {
    var iter = dir.iterate();
    const filesNumber: u64 = try nfilesInDir(io, dir);

    if (filesNumber == 0) return &[0]std.Io.Dir.Entry{};

    var arr: []std.Io.Dir.Entry = try allocator.alloc(std.Io.Dir.Entry, filesNumber);

    var i: u64 = 0;

    while (iter.next(io)) |file| {
        if (file) |f| {
            arr[i] = std.Io.Dir.Entry{ .name = try allocator.dupe(u8, f.name), .kind = f.kind, .inode = f.inode };
            i += 1;
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    return arr;
}
/// prints content of directory
pub fn printDir(init: std.process.Init, dir: std.Io.Dir, writer: *std.Io.File.Writer) !void {
    const io = init.io;
    const write = &writer.interface;

    var iter = dir.iterate();

    while (iter.next(io)) |file| {
        if (file) |f| {
            switch (f.kind) {
                .directory => {
                    try write.print("{s}/\n", .{f.name});
                },
                else => try write.print("{s}\n", .{f.name}),
            }
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    try write.flush();
}
