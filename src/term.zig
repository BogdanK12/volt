const std = @import("std");
const termios = std.os.linux.termios;

pub const Term = @This();

prev_state: termios = undefined,
cur_state: termios = undefined,
width: i64 = 0,
height: i64 = 0,

/// returns current settings of terminal
pub fn initTerm(term: *Term) void {
    _ = std.os.linux.tcgetattr(std.os.linux.STDIN_FILENO, &term.cur_state);
    term.cur_state = term.prev_state;
}

/// sets terminal to raw mode
pub fn enableRawMode(term: *Term) void {
    term.cur_state.lflag.ECHO = false;
    _ = std.os.linux.tcsetattr(std.os.linux.STDIN_FILENO, std.posix.TCSA.NOW, &term.cur_state);
}

pub fn disableRawMode(term: *Term) void {
    _ = std.os.linux.tcsetattr(std.os.linux.STDIN_FILENO, std.posix.TCSA.NOW, &term.prev_state);
}
