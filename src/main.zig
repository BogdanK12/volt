const std = @import("std");
const Io = std.Io;

const volt = @import("volt");

fn printDir(init: std.process.Init, dir: std.Io.Dir, writer: *std.Io.File.Writer) !void {
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

fn nfilesInDir(
    init: std.process.Init,
    dir: std.Io.Dir,
) !u64 {
    const io = init.io;
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

fn dirToArray2(
    init: std.process.Init,
    dir: Io.Dir,
) ![][]u8 {
    const io = init.io;
    var iter = dir.iterate();
    const filesNumber: u64 = try nfilesInDir(init, dir);

    if (filesNumber == 0) return &[_][]u8{};

    // var arr: [][]const u8 = try init.arena.allocator().alloc([]const u8, filesNumber);
    var arr: [][]u8 = try init.gpa.alloc([]u8, filesNumber);

    var i: u64 = 0;

    while (iter.next(io)) |file| {
        if (file) |f| {
            arr[i] = try init.gpa.dupe(u8, f.name);
            i += 1;
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    return arr;
}

fn dirToArray(
    init: std.process.Init,
    dir: std.Io.Dir,
) ![][]const u8 {
    const io = init.io;
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

    if (filesNumber == 0) return &[_][]u8{};

    // var arr: [][]const u8 = try init.arena.allocator().alloc([]const u8, filesNumber);
    var arr: [][]const u8 = try init.gpa.alloc([]const u8, filesNumber);

    iter = dir.iterate();

    var i: u64 = 0;

    while (iter.next(io)) |file| {
        if (file) |f| {
            arr[i] = f.name;
            i += 1;
        } else {
            break;
        }
    } else |err| {
        return err;
    }

    return arr;
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    _ = &args;
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    const io = init.io;
    const cwd: Io.Dir = try Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);

    // try printDir(init, cwd, &stdout_file_writer);
    const arr = try dirToArray2(init, cwd);
    defer init.gpa.free(arr);

    // const f = try nfilesInDir(init, cwd);

    // for (0..f) |i| {
    //     try stdout_file_writer.interface.print("{s}\n", .{arr[i]});
    //     init.gpa.free(arr[i]);
    // }

    for (arr) |i| {
        try stdout_file_writer.interface.print("{s}\n", .{i});
        init.gpa.free(i);
    }

    try stdout_file_writer.interface.flush();
}
