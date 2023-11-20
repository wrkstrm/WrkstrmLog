import Logging

extension Logging.Logger.Level {
  /// Converts a `Logging.Logger.Level` to an emoji.
  ///
  /// This extension allows for visually representing Swift Log levels using emojis, which can
  /// be useful for quick visual identification in logs.
  ///
  /// - Returns: An emoji equivalent to the Swift Log level.
  public var emoji: String {
    switch self {
      case .trace:
        "🔍"  // Trace - Looking closely into details
      case .debug:
        "🐞"  // Debug - Finding bugs
      case .info:
        "ℹ️"  // Info - General information
      case .notice:
        "📝"  // Notice - Something to take note of
      case .warning:
        "⚠️"  // Warning - Potential problem
      case .error:
        "❗"  // Error - An error has occurred
      case .critical:
        "🚨"  // Critical - A critical issue
    }
  }
}
