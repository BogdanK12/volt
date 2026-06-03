const std = @import("std");
const posix = std.posix;
const termios = posix.termios;

pub const Term = @This();

const Error = error{
    IoctlFailed,
};

prev_state: termios = undefined,
cur_state: termios = undefined,
window: posix.winsize = undefined,

/// returns current settings of terminal
pub fn initTerm(self: *Term) !void {
    self.prev_state = try posix.tcgetattr(posix.STDIN_FILENO);
    self.cur_state = self.prev_state;
    try self.getSize();
}

/// sets terminal to raw mode through posix API
pub fn enableRawMode(self: *Term) !void {
    self.cur_state.lflag.ECHO = false;
    self.cur_state.lflag.ICANON = false;
    self.cur_state.lflag.IEXTEN = false;

    self.cur_state.iflag.IXON = false;

    _ = try posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, self.cur_state);
}

/// disables raw mode through posix API
pub fn disableRawMode(self: *Term) !void {
    _ = try std.posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, self.prev_state);
}

/// get window size
pub fn getSize(self: *Term) !void {
    if (std.os.linux.ioctl(posix.STDIN_FILENO, std.os.linux.T.IOCGWINSZ, @intFromPtr(&self.window)) == -1)
        return Error.IoctlFailed;
}
