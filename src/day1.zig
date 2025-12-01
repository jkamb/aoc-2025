const std = @import("std");

const Errors = error{InvalidInput};

const Left = struct { ticks: u16 };
const Right = struct { ticks: u16 };
const RotationType = enum { left, right };
const Rotation = union(RotationType) { left: Left, right: Right };

fn printRotation(rotation: Rotation) void {
    switch (rotation) {
        .left => |left| std.debug.print("Left: {d}\n", .{left.ticks}),
        .right => |right| std.debug.print("Right: {d}\n", .{right.ticks}),
    }
}
fn printRotations(rotations: []Rotation) void {
    for (rotations) |rotation| {
        printRotation(rotation);
    }
}

fn parse(input: []const u8, allocator: std.mem.Allocator) ![]Rotation {
    var rotations: std.ArrayList(Rotation) = .empty;
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        const rotation = switch (line[0]) {
            'L' => Rotation{ .left = .{ .ticks = try std.fmt.parseInt(u16, line[1..], 10) } },
            'R' => Rotation{ .right = .{ .ticks = try std.fmt.parseInt(u16, line[1..], 10) } },
            else => return Errors.InvalidInput
        };
        try rotations.append(allocator, rotation);
    }

    return rotations.toOwnedSlice(allocator);
}

fn part1(input: []Rotation) u32 {
    var current_rotation: i32 = 50;
    var zero_count: u32 = 0;

    for (input) |rotation| {
        switch (rotation) {
            .left => |left| {
                current_rotation -= left.ticks;
            },
            .right => |right| {
                current_rotation += right.ticks;
            }
        }
        current_rotation = @mod(current_rotation, 100);

        if (current_rotation == 0) {
            zero_count += 1;
        }
    }

    return zero_count;
}

fn part2(input: []Rotation) u32 {
    var current_rotation: i32 = 50;
    var zero_count: u32 = 0;

    for (input) |rotation| {
        const at_zero = current_rotation == 0;
        switch (rotation) {
            .left => |left| {
                current_rotation -= left.ticks;
            },
            .right => |right| {
                current_rotation += right.ticks;
            }
        }

        if (current_rotation <= 0) {
            const div = @abs(@divTrunc(current_rotation, 100)) + 1;
            zero_count += div - @intFromBool(at_zero);
        }

        if (current_rotation >= 100) {
            const div = @divTrunc(current_rotation, 100);
            zero_count += @intCast(div);
        }

        current_rotation = @mod(current_rotation, 100);
    }

    return zero_count;
}

const puzzle_input = @embedFile("day1input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const input = try parse(puzzle_input, allocator);
    defer allocator.free(input);
    const part1_result = part1(input);
    std.debug.print("Part1: {d}\n", .{part1_result});
    const part2_result = part2(input);
    std.debug.print("Part2: {d}\n", .{part2_result});
}

const test_input =
    \\L68
    \\L30
    \\R48
    \\L5
    \\R60
    \\L55
    \\L1
    \\L99
    \\R14
    \\L82
;

test "test parse" {
    const gpa = std.testing.allocator;
    const rotations = try parse(test_input, gpa);
    defer gpa.free(rotations);
}

test "test part1" {
    const gpa = std.testing.allocator;
    const rotations = try parse(test_input, gpa);
    defer gpa.free(rotations);
    const count = part1(rotations);
    try std.testing.expectEqual(@as(u32, 3), count);
}

test "test part2" {
    const gpa = std.testing.allocator;
    const rotations = try parse(test_input, gpa);
    defer gpa.free(rotations);
    const count = part2(rotations);
    try std.testing.expectEqual(@as(u32, 6), count);
}
