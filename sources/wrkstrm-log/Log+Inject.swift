#if canImport(Foundation)
import Foundation
#endif

extension Log {
  /// Runtime injection points for choosing alternate implementations.
  public enum Inject {
    // Toggle for path info cache usage. When false, compute path info without touching the cache.
    internal nonisolated(unsafe) static var pathInfoCacheEnabled: Bool = true

    /// Returns path information for a given file using the configured provider.
    internal static func pathInfo(for file: String) -> Cache.PathInfo {
      if pathInfoCacheEnabled {
        LogTrace.log("pathInfo", "cache-on file=\(file)")
        return Cache.shared.pathInfo(for: file)
      } else {
        LogTrace.log("pathInfo", "cache-off file=\(file)")
        #if os(WASI) || arch(wasm32)
        let last = file.split(separator: "/").last.map(String.init) ?? file
        let trimmed = last.hasSuffix(".swift") ? String(last.dropLast(6)) : last
        return Cache.PathInfo(url: file, fileName: trimmed, lastPathComponent: last)
        #else
        #if canImport(Foundation)
        let url = URL(fileURLWithPath: file)
        let lastComponent = url.lastPathComponent
        let trimmed = lastComponent.replacingOccurrences(of: ".swift", with: "")
        return Cache.PathInfo(url: url, fileName: trimmed, lastPathComponent: lastComponent)
        #else
        let last = file.split(separator: "/").last.map(String.init) ?? file
        let trimmed = last.hasSuffix(".swift") ? String(last.dropLast(6)) : last
        // Use the string form when Foundation URL isn't present
        return Cache.PathInfo(url: file, fileName: trimmed, lastPathComponent: last)
        #endif
        #endif
      }
    }

    /// Configures whether file path information should be cached or computed each call.
    /// - Parameter useCache: When `true`, path info results are cached and reused. When `false`,
    ///   path info is recalculated every time without updating the cache.
    public static func usePathInfoCache(_ useCache: Bool) {
      pathInfoCacheEnabled = useCache
      LogTrace.log("inject", "usePathInfoCache=\(useCache)")
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

    /// Runtime-selected ordered list of backends. When set, index 0 is treated
    /// as the primary backend. If unset, resolution falls back to the platform
    /// default for the current build environment.
    internal nonisolated(unsafe) static var selectedBackends: [Backend]? = nil

    /// Convenience: selects a single active backend at runtime.
    /// Same as calling `setBackends([backend])`.
    /// - Note: On WASM builds, selection is clamped to `.print`.
    public static func setBackend(_ backend: Backend) {
      #if os(WASI) || arch(wasm32)
      selectedBackends = [.print]
      #else
      selectedBackends = [backend]
      #endif
    }

    /// Selects the active ordered list of backends at runtime.
    /// - Note: On WASM builds, selection is clamped to `[.print]` regardless of input.
    public static func setBackends(_ backends: [Backend]) {
      #if os(WASI) || arch(wasm32)
      selectedBackends = [.print]
      #else
      // Preserve order; empty input resets to platform default behavior.
      selectedBackends = backends.isEmpty ? nil : backends
      #endif
    }

    /// Appends a backend to the ordered list if not already present.
    /// If no backends are set yet, this becomes the sole backend.
    /// - Note: On WASM builds, selection is clamped to `[.print]`.
    public static func appendBackend(_ backend: Backend) {
      #if os(WASI) || arch(wasm32)
      selectedBackends = [.print]
      return
      #else
      if selectedBackends == nil {
        selectedBackends = [backend]
        return
      }
      if let existing = selectedBackends, !existing.contains(backend) {
        selectedBackends = existing + [backend]
      }
      #endif
    }

    /// Removes a backend kind from the ordered list, if present.
    /// If the list becomes empty, reverts to platform default behavior.
    /// - Note: On WASM builds, selection is clamped to `[.print]`.
    public static func removeBackend(_ backend: Backend) {
      #if os(WASI) || arch(wasm32)
      selectedBackends = [.print]
      return
      #else
      guard let existing = selectedBackends else { return }
      let filtered = existing.filter { $0 != backend }
      if filtered.isEmpty {
        selectedBackends = nil
      } else {
        selectedBackends = filtered
      }
      #endif
    }

    /// Clears any custom backend selection, reverting to platform default behavior.
    /// On WASM, clamps to `[.print]`.
    public static func removeAllCustomBackends() {
      #if os(WASI) || arch(wasm32)
      selectedBackends = [.print]
      #else
      selectedBackends = nil
      #endif
    }

    /// Resolves the effective backend for the current platform and selection.
    internal static func currentBackend() -> Backend {
      // Prefer array resolution when available.
      if let first = currentBackends().first {
        return first
      }
      // Should not happen; return platform default.
      #if os(WASI) || arch(wasm32)
      return .print
      #elseif canImport(os)
      return .os
      #else
      return .swift
      #endif
    }

    /// Resolves the effective ordered list of backends for the current platform
    /// and selection. When not explicitly set, returns a single platform-default
    /// backend.
    internal static func currentBackends() -> [Backend] {
      if let explicit = selectedBackends {
        #if os(WASI) || arch(wasm32)
        return [.print]
        #else
        return explicit
        #endif
      }
      // Platform default when no explicit selection is set.
      #if os(WASI) || arch(wasm32)
      return [.print]
      #elseif canImport(os)
      return [.os]
      #else
      return [.swift]
      #endif
    }

    /// Reset injection state to platform defaults. Intended for tests.
    internal static func resetInjection() {
      selectedBackends = nil
    }
  }
}
