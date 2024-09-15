pub const ContextStatus = enum {
    Continue,
    Spawn,
    Stop,
    Return,
    Revert,
    Panic,
    OutOfGas,
};
