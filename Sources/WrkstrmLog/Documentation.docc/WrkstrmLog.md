@Metadata {
@Title("WrkstrmLog")
@PageKind(article)
}

WrkstrmLog is a flexible, multi‑backend logging library. It is a flagship module for observability practices and documentation quality.

## Topics

### Core

- `Log`
- `LogGroup`
- `LogBackend`

### Guides

- <doc:GettingStarted>
- <doc:LogIndex>
- <doc:BackendsOverview>
- <doc:DecoratorsOverview>

### Decorators

- `Log/Decorator`

### Backends

- `PrintLogBackend`
- `SwiftLogBackend`
  #if canImport(os)
- `OSLogBackend`
  #endif
- `DisabledLogBackend`
