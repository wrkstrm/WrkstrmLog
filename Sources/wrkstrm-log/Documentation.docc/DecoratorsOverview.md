# Decorators overview

Decorators control how a `Log` formats its message body.

## JSON Decorator

Structured output with metadata; pair with file backend for NDJSON.

```swift
#if canImport(Foundation)
import Foundation
import WrkstrmLog

var log = Log(system: "App", category: "json")
log.decorator = Log.Decorator.JSON()
log.info("hello")
#endif
```

## Plain Decorator

Just the message body.

```swift
import WrkstrmLog

var log = Log(system: "App", category: "plain")
log.decorator = Log.Decorator.Plain()
log.info("hello")
```
