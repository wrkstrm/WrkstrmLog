# Log Levels

Understand the purpose of each log level in WrkstrmLog.

WrkstrmLog provides seven levels with increasing severity. `verbose`
messages are emitted at the `debug` level.

## Trace
Use trace for the most detailed events, like entering and exiting functions
or iterating over loops.
```swift
logger.trace("starting request")
```

## Debug
Diagnostic information that helps during development. `verbose` is an alias
for this level.
```swift
logger.debug("parsed response: \(response)")
```

## Info
General operational messages that track the progress of your app.
```swift
logger.info("request completed")
```

## Notice
Important events that aren't problems but are worth noting.
```swift
logger.notice("user signed in")
```

## Warning
Potential issues that might require attention.
```swift
logger.warning("retrying after timeout")
```

## Error
A recoverable failure within the application.
```swift
logger.error("failed to save item: \(error)")
```

## Critical
Severe problems that usually terminate execution or cause data loss.
```swift
Log.guard("database unavailable")
```
