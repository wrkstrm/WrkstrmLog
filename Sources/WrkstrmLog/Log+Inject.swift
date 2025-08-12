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
  }
}
