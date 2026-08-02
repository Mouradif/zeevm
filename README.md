# ZeeVM

An implementation of the EVM written in Zig.

## Requirements

- Zig `0.16.0` — see [ziglang.org/download](https://ziglang.org/download/) for installation instructions.

## Building

```sh
zig build
```

## Running tests

```sh
zig build test
```

A handful of tests in `src/utils/rpc/rpc_client.zig` hit a live RPC endpoint (`rpc.flashbots.net`) and pin real mainnet state (block number, nonce, storage), so they can drift or fail without network access.

## Running the examples

```sh
zig build example -- snailtracer
zig build example -- replay
```

- `snailtracer` runs a bundled bytecode contract locally against an in-memory state.
- `replay` forks live state from a remote RPC endpoint (see `fork_url` in `examples/replay.zig`) and replays a call against it.

## Build options

Pass these with `-D<option>=true`, e.g. `zig build test -Dtrace=true -Dgas=true`:

- `trace` — print each executed opcode as it runs.
- `gas` — alongside `trace`, also print the gas used per opcode.
- `debug` — print extra diagnostics from the interpreter.
- `bench` — print the total wall-clock time spent in `EVM.run`.

## Acknowledgements

- [rauljordan/zevm](https://github.com/rauljordan/zevm): At first I wanted to fork this repo and complete it but I ended up starting fresh.
