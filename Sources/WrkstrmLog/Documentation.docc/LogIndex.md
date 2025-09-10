@Metadata {
@Title("Logging Index")
@PageKind(article)
}

Key logging symbols and structure in WrkstrmLog.

## Topics

### Loggers

- `Log`
- `LogGroup`

### Backends

- `LogBackend`
- `PrintLogBackend`
- `SwiftLogBackend`
  #if canImport(os)
- `OSLogBackend`
  #endif
- `DisabledLogBackend`

### Decoration

- `Log/Decorator`
- `Log/Decorator/JSON`
- `Log/Decorator/Plain`
