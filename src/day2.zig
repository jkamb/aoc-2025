const std = @import("std");

const Errors = error{InvalidInput};

const Range = struct {
    start: u64,
    end: u64,
};

fn RangeIterator() type {
    return struct {
        const Self = @This();
        start: u64,
        end: u64,
        index: ?u64 = null,

        pub fn next(self: *Self) ?u64 {
            if (self.index == null) {
                self.index = self.start;
                return self.start;
            }
            self.index.? += 1;
            return if (self.index.? <= self.end) self.index.? else null;
        }
    };
}

fn rangeIterator(r: Range) RangeIterator() {
    return .{ .start = r.start, .end = r.end };
}

fn printRange(r: Range) void {
    std.debug.print("{d}-{d}\n", .{ r.start, r.end });
}

fn parse(input: []const u8, allocator: std.mem.Allocator) ![]Range {
    var ranges: std.ArrayList(Range) = .empty;
    errdefer ranges.deinit(allocator);
    var pairs = std.mem.tokenizeScalar(u8, input, ',');
    while (pairs.next()) |pair| {
        var bounds = std.mem.tokenizeScalar(u8, pair, '-');
        const begin = bounds.next() orelse return Errors.InvalidInput;
        const end = bounds.next() orelse return Errors.InvalidInput;
        try ranges.append(allocator, Range{ .end = try std.fmt.parseInt(u64, end, 10), .start = try std.fmt.parseInt(u64, begin, 10) });
    }

    return ranges.toOwnedSlice(allocator);
}

fn isInvalid(n: u64, check_twice: bool) bool {
    var num = n;
    var digits: u32 = 0;
    while (num != 0) {
        num /= 10;
        digits += 1;
    }
    return if (check_twice == true) checkTwice(n, digits) else checkTwiceOrMore(n, digits);
}

fn checkTwice(n: u64, digits: u32) bool {
    if (digits % 2 != 0) {
        return false;
    }
    const mid = digits / 2;
    const divisor = std.math.pow(u32, 10, mid);
    const left = n / divisor;
    const right = n % divisor;
    return left == right;
}

fn checkTwiceOrMore(n: u64, digits: u32) bool {
    for (1..digits / 2 + 1) |k| {
        if (digits % k != 0) {
            continue;
        }
        const divisor = std.math.pow(u64, 10, digits - k);
        const pattern = n / divisor;
        var repeated: u64 = 0;
        for (0..digits / k) |_| {
            repeated = (repeated * std.math.pow(u64, 10, k)) + pattern;
        }
        if (repeated == n) {
            return true;
        }
    }
    return false;
}

fn part1(ranges: []Range) u64 {
    var result: u64 = 0;
    for (ranges) |r| {
        var it = rangeIterator(r);
        while (it.next()) |num| {
            if (isInvalid(num, true)) {
                result += num;
            }
        }
    }
    return result;
}

fn part2(ranges: []Range) u64 {
    var result: u64 = 0;
    for (ranges) |r| {
        var it = rangeIterator(r);
        while (it.next()) |num| {
            if (isInvalid(num, false)) {
                result += num;
            }
        }
    }
    return result;
}

const puzzle_input = @embedFile("day2input.txt");

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

const test_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

test "test invalid" {
    try std.testing.expect(isInvalid(11, true));
    try std.testing.expect(!isInvalid(12, true));
    try std.testing.expect(isInvalid(2323, true));
    try std.testing.expect(isInvalid(1188511885, true));
}

test "part 2" {
    try std.testing.expect(isInvalid(12341234, false));
    try std.testing.expect(isInvalid(123123123, false));
    try std.testing.expect(isInvalid(1212121212, false));
    try std.testing.expect(isInvalid(1111111, false));
}

test "test parse" {
    const gpa = std.testing.allocator;
    const ranges = try parse(test_input, gpa);
    defer gpa.free(ranges);
}

test "test part1" {
    const gpa = std.testing.allocator;
    const ranges = try parse(test_input, gpa);
    defer gpa.free(ranges);
    const count = part1(ranges);
    try std.testing.expectEqual(@as(u32, 1227775554), count);
}

test "test part2" {
    const gpa = std.testing.allocator;
    const ranges = try parse(test_input, gpa);
    defer gpa.free(ranges);
    const count = part2(ranges);
    try std.testing.expectEqual(@as(u32, 4174379265), count);
}
