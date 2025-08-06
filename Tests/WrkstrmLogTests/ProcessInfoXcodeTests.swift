import Foundation
import Testing

@testable import WrkstrmLog

#if canImport(Darwin)
  import Darwin
#else
  import Glibc
#endif

@Suite("ProcessInfo Xcode detection", .serialized)
struct ProcessInfoXcodeTests {
  func withEnv(_ key: String, value: String?) -> () -> Void {
    let old = getenv(key).map { String(cString: $0) }
    if let value {
      setenv(key, value, 1)
    } else {
      unsetenv(key)
    }
    return {
      if let old {
        setenv(key, old, 1)
      } else {
        unsetenv(key)
      }
    }
  }

  @Test
  func detectsBundleIdentifier() {
    let restore = withEnv("__CFBundleIdentifier", value: "com.apple.dt.Xcode")
    defer { restore() }
    #expect(ProcessInfo.inXcodeEnvironment)
  }

  @Test
  func detectsDyldLibraryPath() {
    let restoreCFBundle = withEnv("__CFBundleIdentifier", value: nil)
    defer { restoreCFBundle() }
    let restore = withEnv("DYLD_LIBRARY_PATH", value: "/tmp/Xcode/Libraries")
    defer { restore() }
    #expect(ProcessInfo.inXcodeEnvironment)
  }

  @Test
  func detectsDyldFrameworkPath() {
    let restoreCFBundle = withEnv("__CFBundleIdentifier", value: nil)
    defer { restoreCFBundle() }
    let restoreLib = withEnv("DYLD_LIBRARY_PATH", value: nil)
    defer { restoreLib() }
    let restore = withEnv("DYLD_FRAMEWORK_PATH", value: "/opt/Xcode/Frameworks")
    defer { restore() }
    #expect(ProcessInfo.inXcodeEnvironment)
  }

  @Test
  func returnsFalseWhenNoIndicators() {
    let restoreCFBundle = withEnv("__CFBundleIdentifier", value: nil)
    defer { restoreCFBundle() }
    let restoreLib = withEnv("DYLD_LIBRARY_PATH", value: nil)
    defer { restoreLib() }
    let restoreFramework = withEnv("DYLD_FRAMEWORK_PATH", value: nil)
    defer { restoreFramework() }
    #expect(!ProcessInfo.inXcodeEnvironment)
  }
}
