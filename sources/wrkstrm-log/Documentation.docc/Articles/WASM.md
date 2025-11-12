# WrkstrmLog on WASM

This document summarizes building and running WrkstrmLog for WebAssembly (WASI) and the differences
from Apple/Linux builds.

## Targeting

- Backend selection is compile-time:
  - `#if os(WASI) || arch(wasm32)`: print backend
  - `#elseif canImport(os)`: OSLog backend (Apple platforms)
  - `#else`: SwiftLog backend (portable)
- API parity: all levels are available on WASM (trace, debug, info, notice, warning, error,
  critical/guard). Metadata support is best-effort (flattened key=value in print backend).
- Dependencies on WASM: no Foundation, no OSLog, no Dispatch.

## Build

Prerequisites:

- Swift toolchain with WASI support (Swift 6.1+ or SwiftWasm toolchain).

Command:

```bash
swift build --target WrkstrmLog --triple wasm32-unknown-wasi -c release
```

Notes:

- On macOS, SwiftPM may use caches under `~/Library`. In restricted environments this can fail.
  Run builds outside of sandboxes that block user Library, or configure your environment to allow
  SwiftPM caches.
- `swift-log` is not linked on WASM; the print backend compiles without it.

## Experience log (Codex macOS)

- Toolchain: Apple Swift 6.2 (swift-driver 1.127.14.1) available.
- Attempted: `swift build --target WrkstrmLog --triple wasm32-unknown-wasi`.
- Result: Build blocked by sandbox writing to `~/Library` for SwiftPM caches. This is an
  environment restriction, not a source issue. Outside the sandbox with a WASI-capable toolchain,
  the package should build, as WASM code compiles out Foundation/OSLog/Dispatch.

## Behavior

- Release builds: logs disabled unless `options: [.prod]` is set when creating a `Log`.
- Debug builds: logs enabled; control verbosity via `Log.globalExposureLevel` and per-logger
  `maxExposureLevel`.
