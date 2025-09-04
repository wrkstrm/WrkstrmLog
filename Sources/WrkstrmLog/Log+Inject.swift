import Foundation

extension Log {
  /// Runtime injection points for choosing alternate implementations.
  public enum Inject {
    // Current path info provider. Defaults to using the shared cache.
    internal nonisolated(unsafe) static var pathInfoProvider: @Sendable (String) -> Cache.PathInfo =
      {
        Cache.shared.pathInfo(for: $0)
      }

    /// Returns path information for a given file using the configured provider.
    internal static func pathInfo(for file: String) -> Cache.PathInfo {
      pathInfoProvider(file)
    }

    /// Configures whether file path information should be cached or computed each call.
    /// - Parameter useCache: When `true`, path info results are cached and reused. When `false`,
    ///   path info is recalculated every time without updating the cache.
    public static func usePathInfoCache(_ useCache: Bool) {
      if useCache {
        pathInfoProvider = { Cache.shared.pathInfo(for: $0) }
      } else {
        pathInfoProvider = { file in
          let url = URL(fileURLWithPath: file)
          let lastComponent = url.lastPathComponent
          let trimmed = lastComponent.replacingOccurrences(of: ".swift", with: "")
          return Cache.PathInfo(url: url, fileName: trimmed, lastPathComponent: lastComponent)
        }
      }
    }

    // MARK: - Backend Selection (Service Architecture)

    /// Supported logging backends.
    public enum Backend: Sendable, Hashable {
      case print
      case swift
      #if canImport(os)
      case os
      #endif
      case disabled
      case auto  // Choose a sensible default for the current platform.
    }

    /// Runtime-selected backend. Defaults to `.auto`.
    internal nonisolated(unsafe) static var selectedBackend: Backend = .auto

    /// Selects the active backend at runtime.
    /// - Note: On WASM builds, selection is clamped to `.print`.
    public static func setBackend(_ backend: Backend) {
      #if os(WASI) || arch(wasm32)
      selectedBackend = .print
      #else
      selectedBackend = backend
      #endif
    }

    /// Resolves the effective backend for the current platform and selection.
    internal static func currentBackend() -> Backend {
      switch selectedBackend {
      case .auto:
        #if os(WASI) || arch(wasm32)
        return .print
        #elseif canImport(os)
        return .os
        #else
        return .swift
        #endif
      default:
        #if os(WASI) || arch(wasm32)
        return .print
        #else
        return selectedBackend
        #endif
      }
    }
  }
}
