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

    run(file);
}

pub fn runPrompt() !void {
    return genError.NotImplementedYet;
}

pub fn run(file: std.fs.File) !void {}

const ArgsError = error{
    IncorrectArguments,
};

const genError = error{
    NotImplementedYet,
    FileNotFound,
};
