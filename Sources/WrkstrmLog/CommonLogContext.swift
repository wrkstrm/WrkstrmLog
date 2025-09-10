import Logging

/// Stateless accessors for common logging context values.
///
/// Implementations should be lightweight and avoid storing state. Callers pass
/// parameters as needed, and the context computes or forwards values appropriate
/// for its target backend (Print, Swift, OS, etc.).
public protocol CommonLogContext: Sendable {
  // Identity
  func system(for log: Log) -> String
  func category(for log: Log) -> String

  // Source info
  func lastPathComponent(for file: String) -> String
  func fileName(for file: String) -> String
  func source(for file: String) -> String
  func formattedFunction(_ name: String, maxLength: Int?) -> String
}

extension CommonLogContext {
  // Defaults shared by most backends
  public func system(for log: Log) -> String { log.system }
  public func category(for log: Log) -> String { log.category }

  public func lastPathComponent(for file: String) -> String {
    Log.Inject.pathInfo(for: file).lastPathComponent
  }

  public func fileName(for file: String) -> String {
    Log.Inject.pathInfo(for: file).fileName
  }

  /// Swift-logging `source` typically uses the last path component.
  public func source(for file: String) -> String { lastPathComponent(for: file) }

  public func formattedFunction(_ name: String, maxLength: Int?) -> String {
    guard let max = maxLength else { return name }
    return String(name.prefix(max))
  }
}

// MARK: - Concrete contexts

/// Print backend context — relies entirely on computed values.
public struct PrintCommonLogContext: CommonLogContext, Sendable {
  public init() {}
}

/// Swift Logging backend context — uses the defaults for source formatting.
public struct SwiftCommonLogContext: CommonLogContext, Sendable {
  public init() {}
}

#if canImport(Foundation) && !os(WASI) && canImport(os)
/// OSLog backend context — default computed values are sufficient.
public struct OSCommonLogContext: CommonLogContext, Sendable {
  public init() {}
}
#endif
