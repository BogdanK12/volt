const std = @import("std");

pub fn nfilesInDir(
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

pub fn dirToArray(
    init: std.process.Init,
    dir: std.Io.Dir,
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
