# Migration Guide: Style → Backend(s)

This guide helps you migrate from legacy “style” APIs to explicit
backend/backend(s). Style APIs are soft‑deprecated now; wrappers remain to ease
incremental migration. The next major (3.0.0) removes them.

## Summary

- `Log.Style` and `init(style:)` are removed.
- Use explicit backend instances. Multi-backend fan-out is supported with
  primary = index 0 (backward-compatible defaults keep a single backend).

## Constructors

```swift
// Single backend
let log1 = Log(system: "App", category: "UI", backends: [OSLogBackend()])
let log2 = Log(system: "Srv", category: "Net", backends: [SwiftLogBackend()])
let log3 = Log(system: "Tool", category: "IO", backends: [PrintLogBackend()])

// Multi-backend fan-out; primary is index 0
let capture = /* CapturingLogBackend(...) */
let log4 = Log(system: "App", category: "UI", backends: [OSLogBackend(), capture])
```

## Injection mappings

```swift
// Select kinds; construction can receive concrete instances
Log.Inject.setBackends([.os])
Log.Inject.setBackends([.swift])
Log.Inject.setBackends([.print])
```

Notes:
- Omit injection to use platform defaults, or set a single explicit backend.
- Multi-backend is optional; the default remains identical to prior releases.

## Primary backend semantics

- When multiple backends are configured, index 0 is treated as the “primary”
  backend for legacy semantics and simple inspection.

## Deprecation timeline

- v1.x: style available; discouraged in docs.
- v2.0.0: backend-first docs; style kept for compatibility in some code paths.
- v3.0.0: remove remaining style APIs; backend/backend(s) required.

## See also

- CHANGELOG “3.0.0” entry for a concise summary.
- README “Migration (next major)” section for quick examples.
