@Metadata {
@Title("Getting Started with WrkstrmLog")
@PageKind(article)
}

Learn the basics of creating loggers, choosing backends, and formatting output.

## Create a Logger

```swift
import WrkstrmLog

let log = Log(system: "App", category: "UI", maxExposureLevel: .info)
log.info("Hello")
```

## Choose a Backend

By default, a reasonable backend is selected per platform. To force one:

```swift
import WrkstrmLog

let printLog = Log(system: "App", category: "print", backends: [PrintLogBackend()])
printLog.info("stdout line")

let swiftLog = Log(system: "App", category: "swift", backends: [SwiftLogBackend()])
swiftLog.info("swift-log line")

#if canImport(os)
let osLogger = Log(system: "App", category: "os", backends: [OSLogBackend()])
osLogger.info("unified logging line")
#endif
```

## Format Output (Decorators)

```swift
var jsonLog = log
#if canImport(Foundation)
jsonLog.decorator = Log.Decorator.JSON()
#endif
jsonLog.info("structured message")

var plainLog = log
plainLog.decorator = Log.Decorator.Plain()
plainLog.info("just the message body")
```

## Fan‑out to Multiple Backends

```swift
let file = FileLogBackend(url: URL(fileURLWithPath: "/tmp/app.log"))
var fileLog = Log(system: "App", category: "file", backends: [file])
fileLog.decorator = Log.Decorator.JSON()

let both = LogGroup([log, fileLog])
both.info("hello")
```
