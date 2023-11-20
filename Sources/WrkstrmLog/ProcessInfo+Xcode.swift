import Foundation

extension ProcessInfo {
  /// Determines if the current process is running within the Xcode environment.
  ///
  /// This property is useful for configuring logging behavior differently when running
  /// in Xcode versus standalone execution.
  ///
  /// - Returns: `true` if running in Xcode, `false` otherwise.
  public static var inXcodeEnvironment: Bool {
    // Check for the Bundle Identifier of Xcode
    if processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode" {
      return true
    }
    // Check for specific paths in DYLD_LIBRARY_PATH that indicate Xcode environment
    if let dyldLibraryPath = processInfo.environment["DYLD_LIBRARY_PATH"],
       dyldLibraryPath.contains("/Xcode.app/") {
      return true
    }
    // Check for specific paths in DYLD_FRAMEWORK_PATH
    if let dyldFrameworkPath = Self.processInfo.environment["DYLD_FRAMEWORK_PATH"],
       dyldFrameworkPath.contains("/Xcode.app/") {
      return true
    }
    return false
  }
}
