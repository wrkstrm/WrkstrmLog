@Metadata {
@Title("Backends Overview")
@PageKind(article)
}

WrkstrmLog supports multiple output backends; pick one per logger or fan‑out to many.

## PrintLogBackend

Logs to standard output; ideal for local dev and CLI tools.

```swift
import WrkstrmLog
let log = Log(system: "App", category: "stdout", backends: [PrintLogBackend()])
log.info("line")
```

## SwiftLogBackend

Bridges to Apple’s SwiftLog for server‑side or multi‑platform consistency.

```swift
let s = Log(system: "App", category: "swift", backends: [SwiftLogBackend()])
s.info("swift-log line")
```

## OSLogBackend (Apple platforms)

Unified Logging System integration on Apple platforms.

```swift
#if canImport(os)
let oslog = Log(system: "App", category: "os", backends: [OSLogBackend()])
oslog.info("unified logging")
#endif
```

## DisabledLogBackend

Silences output completely.

```swift
let quiet = Log(system: "App", category: "silent", backends: [DisabledLogBackend()])
quiet.info("won't print")
```
