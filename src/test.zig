test "Stack" {
    _ = @import("lib/stack.zig");
}

test "Memory" {
    _ = @import("lib/memory.zig");
}

test "Address State" {
    _ = @import("lib/address_state.zig");
}

test "Context" {
    _ = @import("lib/context.zig");
}

test "EVM" {
    _ = @import("lib/evm.zig");
}

test "Utils: Hex - RPCClient" {
    _ = @import("utils/test.zig");
}

test "Interpreter" {
    _ = @import("lib/interpreter.zig");
}
