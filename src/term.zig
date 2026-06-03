const std = @import("std");
const termios = std.os.linux.termios;

pub const Term = @This();

prev_state: termios = undefined,
cur_state: termios = undefined,
width: i64 = 0,
height: i64 = 0,

/// returns current settings of terminal
pub fn initTerm(self: *Term) void {
    _ = std.os.linux.tcgetattr(std.os.linux.STDIN_FILENO, &self.prev_state);
    self.cur_state = self.prev_state;
}

/// sets terminal to raw mode
pub fn enableRawMode(self: *Term) void {
    self.cur_state.lflag.ECHO = false;
    self.cur_state.lflag.ICANON = false;
    self.cur_state.lflag.IEXTEN = false;

    self.cur_state.iflag.IXON = false;

    _ = std.os.linux.tcsetattr(std.os.linux.STDIN_FILENO, std.posix.TCSA.FLUSH, &self.cur_state);
}

pub fn disableRawMode(self: *Term) void {
    _ = std.os.linux.tcsetattr(std.os.linux.STDIN_FILENO, std.posix.TCSA.FLUSH, &self.prev_state);
}
