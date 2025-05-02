const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const global_allocator = gpa.allocator();

    defer {
        const check = gpa.deinit();
        if (check == std.heap.Check.leak) {
            std.debug.print("Memory leak detected\n", .{});
        }
    }

    const args = try processArgs(global_allocator);
    defer args.deinit();
    defer for (args.items) |i| args.allocator.free(i);

    switch (args.items.len) {
        1 => {
            try runPrompt();
        },
        2 => {
            try runFile(args.items[1]);
        },
        else => {
            std.log.err("Usage: jlox [script]", .{});
        },
    }
}

pub fn processArgs(allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(allocator);

    while (args.next()) |arg| {
        try arg_list.append(try allocator.dupe(u8, arg));
    }

    return arg_list;
}

pub fn runFile(path: []const u8) !void {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return genError.FileNotFound;
    };
    defer file.close();

    try run(file);
}

pub fn runPrompt() !void {
    return genError.NotImplementedYet;
}

pub fn run(file: std.fs.File) !void {
    var scanner = Scanner{
        .source = file,
    };

    const tokens = try scanner.scanTokens();
    _ = tokens;
}

pub fn errorT(line: i32, message: []const u8) !void {
    report(line, "", message);
}

pub fn report(line: i32, where: []const u8, message: []const u8) !void {
    std.log.err("[Line {d} ] Error {s} : {s}", .{ line, where, message });
}

const Scanner = struct {
    source: std.fs.File,

    pub fn scanTokens(self: *Scanner) ![]const []const u8 {
        _ = self;
        return genError.NotImplementedYet;
    }
};

// zig fmt: off
const TokenType = enum {
  // Single-character tokens.
  LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
  COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

  // One or two character tokens.
  BANG, BANG_EQUAL,
  EQUAL, EQUAL_EQUAL,
  GREATER, GREATER_EQUAL,
  LESS, LESS_EQUAL,

  // Literals.
  IDENTIFIER, STRING, NUMBER,

  // Keywords.
  AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
  PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

  EOF,
};
// zig fmt: on

const Literal = union(enum) {
    nil,
    integer: i32,
    float: f32,
    string: []const u8,
    boolean: bool,

    pub fn format(self: Literal, comptime fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = fmt;
        _ = options;
        return switch (self) {
            .nil => writer.writeAll("nil"),
            .integer => |n| std.fmt.format(writer, "{d}", .{n}),
            .float => |n| std.fmt.format(writer, "{d}", .{n}),
            .string => |s| std.fmt.format(writer, "\"{s}\"", .{s}),
            .boolean => |b| std.fmt.format(writer, "{}", .{b}),
        };
    }
};

const Token = struct {
    type: TokenType,
    string: []const u8,
    literal: Literal,
    line: i32,

    pub fn format(self: Token, comptime fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{s} {s} {}", .{
            @tagName(self.type),
            self.string,
            self.literal,
        });
    }
};

const ArgsError = error{
    IncorrectArguments,
};

const genError = error{
    NotImplementedYet,
    FileNotFound,
};
